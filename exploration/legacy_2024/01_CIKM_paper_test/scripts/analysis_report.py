#!/usr/bin/env python3
"""
Analysis Report for CULTIVATE Mapping Pipeline
Analyzes automation recall and precision metrics by language and version
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import re
from pathlib import Path
from datetime import datetime
from urllib.parse import urlparse

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10


def normalize_url(url):
    """
    Normalize URL for matching (matches dbt logic in stg_ground_truth.sql)

    Normalization steps:
    1. Remove http:// or https://
    2. Remove www.
    3. Remove query parameters and fragments
    4. Remove trailing slashes
    5. Remove trailing quotes
    6. Remove whitespace
    7. Convert to lowercase
    """
    if pd.isna(url):
        return ''

    url = str(url).strip()

    # Remove http:// or https:// and optional www.
    url = re.sub(r'^https?://(www\.)?', '', url, flags=re.IGNORECASE)

    # Remove query parameters and fragments
    url = re.sub(r'[?#].*$', '', url)

    # Remove trailing slashes
    url = re.sub(r'/+$', '', url)

    # Remove trailing quotes
    url = re.sub(r"'+$", '', url)

    # Remove any whitespace
    url = re.sub(r'\s+', '', url)

    # Convert to lowercase
    url = url.lower()

    return url


def extract_domain(url):
    """
    Extract domain from URL (matches dbt logic in stg_ground_truth.sql)

    Examples:
    - https://www.example.com/path -> example.com
    - example.com/path -> example.com
    - https://example.com -> example.com
    """
    if pd.isna(url):
        return ''

    url = str(url).strip()

    # Remove http:// or https:// and optional www.
    url = re.sub(r'^https?://(www\.)?', '', url, flags=re.IGNORECASE)

    # Remove everything after first slash
    url = re.sub(r'/.*$', '', url)

    # Convert to lowercase
    url = url.lower()

    return url


class CultivateAnalyzer:
    """Analyzer for CULTIVATE mapping pipeline data"""

    def __init__(self, data_dir='data'):
        """Initialize analyzer with data directory"""
        self.data_dir = Path(data_dir)
        self.ground_truth = None
        self.automation = None
        self.automation_reviewed = None
        self.city_language = None

    def load_data(self):
        """Load all CSV files"""
        print("Loading data files...")

        self.ground_truth = pd.read_csv(
            self.data_dir / 'ground_truth.csv',
            encoding='utf-8-sig'  # Handle BOM
        )
        self.automation = pd.read_csv(
            self.data_dir / 'automation.csv',
            encoding='utf-8-sig'
        )
        self.automation_reviewed = pd.read_csv(
            self.data_dir / 'automation_reviewed.csv',
            encoding='utf-8-sig'
        )
        self.city_language = pd.read_csv(
            self.data_dir / 'city_language.csv',
            encoding='utf-8-sig'
        )

        # Clean whitespace
        for df in [self.ground_truth, self.automation, self.automation_reviewed, self.city_language]:
            df.columns = df.columns.str.strip()
            for col in df.select_dtypes(include=['str']).columns:
                df[col] = df[col].str.strip()

        # Normalize city names to lowercase for consistent joins
        self.ground_truth['city'] = self.ground_truth['city'].str.lower()
        self.automation['city'] = self.automation['city'].str.lower()
        self.city_language['city'] = self.city_language['city'].str.lower()

        # Normalize URLs for matching (using same logic as dbt staging models)
        self.ground_truth['source_url_norm'] = self.ground_truth['source_url'].apply(normalize_url)
        self.automation['source_url_norm'] = self.automation['source_url'].apply(normalize_url)

        # Extract domain for domain-level matching
        self.ground_truth['domain'] = self.ground_truth['source_url'].apply(extract_domain)
        self.automation['domain'] = self.automation['source_url'].apply(extract_domain)

        # Extract version from run_id
        self.automation['version'] = self.automation['run_id'].str.extract(r'(v\d+)$')[0]

        # Merge automation with reviews
        self.automation = self.automation.merge(
            self.automation_reviewed,
            on='automation_id',
            how='left'
        )

        # Convert is_included to boolean
        self.automation['is_included_bool'] = (
            self.automation['is_included'].str.strip().str.upper() == 'TRUE'
        )

        # Add language to datasets
        self.ground_truth = self.ground_truth.merge(
            self.city_language,
            on='city',
            how='left'
        )
        self.automation = self.automation.merge(
            self.city_language,
            on='city',
            how='left'
        )

        print("Data loaded successfully!")
        print(f"  Ground truth: {len(self.ground_truth)} URLs")
        print(f"  Automation: {len(self.automation)} URLs")
        print(f"  Cities: {self.city_language['city'].nunique()}")
        print(f"  Languages: {self.city_language['search_language'].nunique()}")

    def calculate_recall(self, group_by=None):
        """
        Calculate recall: what % of ground_truth was found by automation?
        Uses DOMAIN-LEVEL matching.

        Args:
            group_by: Column(s) to group by (e.g., 'search_language', 'city')

        Returns:
            DataFrame with recall metrics
        """
        # Mark ground truth URLs found in automation (using domain-level matching)
        gt_with_match = self.ground_truth.copy()
        gt_with_match['found'] = gt_with_match['domain'].isin(
            self.automation['domain']
        )

        if group_by:
            if not isinstance(group_by, list):
                group_by = [group_by]

            recall = gt_with_match.groupby(group_by).agg({
                'ground_truth_id': 'count',
                'found': 'sum'
            }).rename(columns={
                'ground_truth_id': 'total_ground_truth',
                'found': 'found_by_automation'
            })

            recall['recall_percent'] = (
                recall['found_by_automation'] / recall['total_ground_truth'] * 100
            ).round(2)
        else:
            total = len(gt_with_match)
            found = gt_with_match['found'].sum()
            recall = pd.DataFrame([{
                'total_ground_truth': total,
                'found_by_automation': found,
                'recall_percent': round(found / total * 100, 2) if total > 0 else 0
            }])

        return recall

    def calculate_precision(self, group_by=None):
        """
        Calculate precision: what % of automation results are correct?

        Args:
            group_by: Column(s) to group by (e.g., 'search_language', 'version')

        Returns:
            DataFrame with precision metrics
        """
        if group_by:
            if not isinstance(group_by, list):
                group_by = [group_by]

            precision = self.automation.groupby(group_by).agg({
                'automation_id': 'count',
                'is_included_bool': 'sum'
            }).rename(columns={
                'automation_id': 'total_automation_results',
                'is_included_bool': 'correct_results'
            })

            precision['precision_percent'] = (
                precision['correct_results'] / precision['total_automation_results'] * 100
            ).round(2)
        else:
            total = len(self.automation)
            correct = self.automation['is_included_bool'].sum()
            precision = pd.DataFrame([{
                'total_automation_results': total,
                'correct_results': correct,
                'precision_percent': round(correct / total * 100, 2) if total > 0 else 0
            }])

        return precision

    def calculate_f1_score(self, recall_pct, precision_pct):
        """Calculate F1 score from recall and precision percentages"""
        if recall_pct > 0 and precision_pct > 0:
            return round(2 * (recall_pct * precision_pct) / (recall_pct + precision_pct), 2)
        return 0.0

    def get_metrics_by_language(self):
        """Get combined metrics by language"""
        recall = self.calculate_recall('search_language')
        precision = self.calculate_precision('search_language')

        metrics = recall.merge(
            precision,
            left_index=True,
            right_index=True,
            how='outer'
        ).fillna(0)

        metrics['f1_score'] = metrics.apply(
            lambda row: self.calculate_f1_score(row['recall_percent'], row['precision_percent']),
            axis=1
        )

        return metrics.reset_index()

    def get_metrics_by_version(self):
        """Get precision metrics by version"""
        return self.calculate_precision('version').reset_index()

    def get_metrics_detailed(self):
        """Get detailed metrics by city, language, and version"""
        recall = self.calculate_recall(['city', 'search_language'])
        precision = self.calculate_precision(['city', 'search_language', 'version'])

        # Merge on city and language
        metrics = recall.reset_index().merge(
            precision.reset_index(),
            on=['city', 'search_language'],
            how='outer'
        ).fillna(0)

        metrics['f1_score'] = metrics.apply(
            lambda row: self.calculate_f1_score(row['recall_percent'], row['precision_percent']),
            axis=1
        )

        return metrics

    def get_missing_ground_truth(self):
        """Get ground truth URLs not found by automation"""
        gt_with_match = self.ground_truth.copy()
        gt_with_match['found'] = gt_with_match['source_url_norm'].isin(
            self.automation['source_url_norm']
        )

        missing = gt_with_match[~gt_with_match['found']][
            ['ground_truth_id', 'city', 'search_language', 'source_url']
        ].copy()

        return missing.sort_values(['city', 'ground_truth_id'])

    def get_false_positives(self):
        """Get automation results marked as incorrect"""
        false_pos = self.automation[~self.automation['is_included_bool']][
            ['automation_id', 'city', 'search_language', 'run_id', 'version', 'source_url']
        ].copy()

        return false_pos.sort_values(['city', 'run_id', 'automation_id'])

    def plot_metrics_by_language(self, save_path=None):
        """Create visualization of metrics by language"""
        metrics = self.get_metrics_by_language()

        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle('CULTIVATE Analysis: Metrics by Language', fontsize=16, fontweight='bold')

        # Recall by language
        ax1 = axes[0, 0]
        metrics.plot(
            x='search_language',
            y='recall_percent',
            kind='bar',
            ax=ax1,
            color='steelblue',
            legend=False
        )
        ax1.set_title('Recall % by Language')
        ax1.set_xlabel('Language')
        ax1.set_ylabel('Recall (%)')
        ax1.set_xticklabels(ax1.get_xticklabels(), rotation=45, ha='right')
        ax1.axhline(y=50, color='r', linestyle='--', alpha=0.5, label='50% threshold')
        ax1.legend()

        # Precision by language
        ax2 = axes[0, 1]
        metrics.plot(
            x='search_language',
            y='precision_percent',
            kind='bar',
            ax=ax2,
            color='darkgreen',
            legend=False
        )
        ax2.set_title('Precision % by Language')
        ax2.set_xlabel('Language')
        ax2.set_ylabel('Precision (%)')
        ax2.set_xticklabels(ax2.get_xticklabels(), rotation=45, ha='right')
        ax2.axhline(y=50, color='r', linestyle='--', alpha=0.5, label='50% threshold')
        ax2.legend()

        # F1 Score by language
        ax3 = axes[1, 0]
        metrics.plot(
            x='search_language',
            y='f1_score',
            kind='bar',
            ax=ax3,
            color='darkorange',
            legend=False
        )
        ax3.set_title('F1 Score by Language')
        ax3.set_xlabel('Language')
        ax3.set_ylabel('F1 Score')
        ax3.set_xticklabels(ax3.get_xticklabels(), rotation=45, ha='right')
        ax3.axhline(y=50, color='r', linestyle='--', alpha=0.5, label='50% threshold')
        ax3.legend()

        # Combined comparison
        ax4 = axes[1, 1]
        x = np.arange(len(metrics))
        width = 0.25

        ax4.bar(x - width, metrics['recall_percent'], width, label='Recall', color='steelblue')
        ax4.bar(x, metrics['precision_percent'], width, label='Precision', color='darkgreen')
        ax4.bar(x + width, metrics['f1_score'], width, label='F1 Score', color='darkorange')

        ax4.set_title('Metrics Comparison by Language')
        ax4.set_xlabel('Language')
        ax4.set_ylabel('Score (%)')
        ax4.set_xticks(x)
        ax4.set_xticklabels(metrics['search_language'], rotation=45, ha='right')
        ax4.legend()
        ax4.axhline(y=50, color='r', linestyle='--', alpha=0.3)

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            print(f"Visualization saved to: {save_path}")

        return fig

    def plot_metrics_by_version(self, save_path=None):
        """Create visualization of metrics by version"""
        metrics = self.get_metrics_by_version()

        fig, ax = plt.subplots(figsize=(10, 6))

        x = np.arange(len(metrics))
        width = 0.35

        ax.bar(x - width/2, metrics['total_automation_results'], width,
               label='Total Results', color='lightblue')
        ax.bar(x + width/2, metrics['correct_results'], width,
               label='Correct Results', color='darkgreen')

        ax.set_title('Automation Results by Version', fontsize=14, fontweight='bold')
        ax.set_xlabel('Version')
        ax.set_ylabel('Count')
        ax.set_xticks(x)
        ax.set_xticklabels(metrics['version'])
        ax.legend()

        # Add precision percentages on top
        for i, row in metrics.iterrows():
            ax.text(i, row['total_automation_results'] + 5,
                   f"{row['precision_percent']:.1f}%",
                   ha='center', va='bottom', fontweight='bold')

        plt.tight_layout()

        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
            print(f"Version visualization saved to: {save_path}")

        return fig

    def generate_report(self, output_dir='reports'):
        """Generate comprehensive analysis report"""
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        report_path = output_dir / f'analysis_report_{timestamp}.txt'

        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("="*80 + "\n")
            f.write("CULTIVATE MAPPING PIPELINE - ANALYSIS REPORT\n")
            f.write("="*80 + "\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            # Overall summary
            f.write("OVERALL SUMMARY\n")
            f.write("-"*80 + "\n")
            overall_recall = self.calculate_recall()
            overall_precision = self.calculate_precision()

            f.write(f"Ground Truth URLs: {overall_recall.iloc[0]['total_ground_truth']}\n")
            f.write(f"Found by Automation: {overall_recall.iloc[0]['found_by_automation']}\n")
            f.write(f"Overall Recall: {overall_recall.iloc[0]['recall_percent']}%\n\n")

            f.write(f"Automation Results: {overall_precision.iloc[0]['total_automation_results']}\n")
            f.write(f"Correct Results: {overall_precision.iloc[0]['correct_results']}\n")
            f.write(f"Overall Precision: {overall_precision.iloc[0]['precision_percent']}%\n\n")

            f1 = self.calculate_f1_score(
                overall_recall.iloc[0]['recall_percent'],
                overall_precision.iloc[0]['precision_percent']
            )
            f.write(f"Overall F1 Score: {f1}\n\n")

            # Metrics by language
            f.write("\n" + "="*80 + "\n")
            f.write("METRICS BY LANGUAGE\n")
            f.write("="*80 + "\n\n")
            metrics_lang = self.get_metrics_by_language()
            f.write(metrics_lang.to_string(index=False))
            f.write("\n\n")

            # Metrics by version
            f.write("="*80 + "\n")
            f.write("METRICS BY VERSION\n")
            f.write("="*80 + "\n\n")
            metrics_ver = self.get_metrics_by_version()
            f.write(metrics_ver.to_string(index=False))
            f.write("\n\n")

            # Detailed metrics
            f.write("="*80 + "\n")
            f.write("DETAILED METRICS (City x Language x Version)\n")
            f.write("="*80 + "\n\n")
            metrics_detail = self.get_metrics_detailed()
            f.write(metrics_detail.to_string(index=False))
            f.write("\n\n")

            # Missing ground truth
            f.write("="*80 + "\n")
            f.write("MISSING GROUND TRUTH URLs\n")
            f.write("="*80 + "\n\n")
            missing = self.get_missing_ground_truth()
            f.write(f"Total missing: {len(missing)}\n\n")
            if len(missing) > 0:
                f.write(missing.to_string(index=False))
            f.write("\n\n")

            # False positives
            f.write("="*80 + "\n")
            f.write("FALSE POSITIVES (Automation results marked as incorrect)\n")
            f.write("="*80 + "\n\n")
            false_pos = self.get_false_positives()
            f.write(f"Total false positives: {len(false_pos)}\n\n")
            if len(false_pos) > 0:
                f.write(false_pos.to_string(index=False))
            f.write("\n\n")

        print(f"\nReport generated: {report_path}")

        # Generate visualizations
        viz_lang_path = output_dir / f'metrics_by_language_{timestamp}.png'
        self.plot_metrics_by_language(save_path=viz_lang_path)

        viz_ver_path = output_dir / f'metrics_by_version_{timestamp}.png'
        self.plot_metrics_by_version(save_path=viz_ver_path)

        print(f"\nAnalysis complete! Check {output_dir} for outputs.")

        return report_path


def main():
    """Main execution function"""
    print("="*80)
    print("CULTIVATE Mapping Pipeline Analysis")
    print("="*80)
    print()

    # Initialize analyzer
    analyzer = CultivateAnalyzer(data_dir='data')

    # Load data
    analyzer.load_data()
    print()

    # Generate report and visualizations
    analyzer.generate_report(output_dir='reports')

    print("\n" + "="*80)
    print("Analysis complete!")
    print("="*80)


if __name__ == '__main__':
    main()
