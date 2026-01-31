#!/usr/bin/env python3
"""
Similarity-based URL Matching Analysis for CULTIVATE Mapping Pipeline
Provides detailed string similarity analysis for manual review
"""

import pandas as pd
import numpy as np
from pathlib import Path
from datetime import datetime
import re
from difflib import SequenceMatcher
from urllib.parse import urlparse


def normalize_url(url):
    """Normalize URL for matching"""
    if pd.isna(url):
        return ''
    url = str(url).strip()
    url = re.sub(r'^https?://(www\.)?', '', url, flags=re.IGNORECASE)
    url = re.sub(r'[?#].*$', '', url)
    url = re.sub(r'/+$', '', url)
    url = re.sub(r"'+$", '', url)
    url = re.sub(r'\s+', '', url)
    return url.lower()


def extract_domain(url):
    """Extract domain from URL"""
    if pd.isna(url):
        return ''
    url = str(url).strip()
    url = re.sub(r'^https?://(www\.)?', '', url, flags=re.IGNORECASE)
    url = re.sub(r'/.*$', '', url)
    return url.lower()


def extract_path_segments(url_norm):
    """Extract path segments from normalized URL"""
    if pd.isna(url_norm) or not url_norm:
        return []

    # Remove domain part
    parts = url_norm.split('/', 1)
    if len(parts) < 2:
        return []

    path = parts[1]
    # Split by / and filter empty strings
    segments = [s for s in path.split('/') if s]
    return segments


def calculate_string_similarity(str1, str2):
    """
    Calculate string similarity using SequenceMatcher (similar to Levenshtein)
    Returns similarity ratio from 0 to 1
    """
    if pd.isna(str1) or pd.isna(str2):
        return 0.0

    str1 = str(str1).lower()
    str2 = str(str2).lower()

    return SequenceMatcher(None, str1, str2).ratio()


def calculate_token_similarity(str1, str2):
    """
    Calculate token-based similarity (Jaccard similarity)
    Splits strings by / and calculates overlap
    """
    if pd.isna(str1) or pd.isna(str2):
        return 0.0

    tokens1 = set(str(str1).lower().split('/'))
    tokens2 = set(str(str2).lower().split('/'))

    if not tokens1 or not tokens2:
        return 0.0

    intersection = tokens1 & tokens2
    union = tokens1 | tokens2

    return len(intersection) / len(union) if union else 0.0


class SimilarityAnalyzer:
    """Analyzer for URL similarity matching"""

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
            encoding='utf-8-sig'
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

        # Normalize
        self.ground_truth['city'] = self.ground_truth['city'].str.lower()
        self.automation['city'] = self.automation['city'].str.lower()
        self.city_language['city'] = self.city_language['city'].str.lower()

        # URL processing
        self.ground_truth['url_norm'] = self.ground_truth['source_url'].apply(normalize_url)
        self.automation['url_norm'] = self.automation['source_url'].apply(normalize_url)

        self.ground_truth['domain'] = self.ground_truth['source_url'].apply(extract_domain)
        self.automation['domain'] = self.automation['source_url'].apply(extract_domain)

        # Extract path segments
        self.ground_truth['path_segments'] = self.ground_truth['url_norm'].apply(extract_path_segments)
        self.automation['path_segments'] = self.automation['url_norm'].apply(extract_path_segments)

        self.ground_truth['path_seg_1'] = self.ground_truth['path_segments'].apply(lambda x: x[0] if len(x) > 0 else None)
        self.automation['path_seg_1'] = self.automation['path_segments'].apply(lambda x: x[0] if len(x) > 0 else None)

        # Merge with reviews
        self.automation = self.automation.merge(
            self.automation_reviewed,
            on='automation_id',
            how='left'
        )
        self.automation['is_included_bool'] = (
            self.automation['is_included'].str.strip().str.upper() == 'TRUE'
        )

        # Extract version
        self.automation['version'] = self.automation['run_id'].str.extract(r'(v\d+)$')[0]

        # Add language
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

    def find_similar_urls(self, city_filter=None, min_similarity=0.0):
        """
        Find similar URLs between ground truth and automation

        Args:
            city_filter: Optional city to filter (e.g., 'cork')
            min_similarity: Minimum similarity score to include (0.0 to 1.0)

        Returns:
            DataFrame with similarity scores
        """
        gt = self.ground_truth.copy()
        auto = self.automation.copy()

        if city_filter:
            gt = gt[gt['city'] == city_filter.lower()]
            auto = auto[auto['city'] == city_filter.lower()]

        results = []

        print(f"\nCalculating similarity for {len(gt)} ground truth URLs...")

        for idx, gt_row in gt.iterrows():
            gt_city = gt_row['city']
            gt_url = gt_row['url_norm']
            gt_domain = gt_row['domain']
            gt_path1 = gt_row['path_seg_1']

            # Filter automation URLs for same city
            auto_city = auto[auto['city'] == gt_city]

            for _, auto_row in auto_city.iterrows():
                auto_url = auto_row['url_norm']
                auto_domain = auto_row['domain']
                auto_path1 = auto_row['path_seg_1']

                # Calculate similarity scores
                url_similarity = calculate_string_similarity(gt_url, auto_url)
                token_similarity = calculate_token_similarity(gt_url, auto_url)

                # Determine match level and confidence
                if gt_url == auto_url:
                    match_level = 'exact_url'
                    confidence = 100
                elif gt_domain == auto_domain and gt_path1 == auto_path1 and gt_path1 is not None:
                    match_level = 'domain_path1'
                    confidence = 75
                elif gt_domain == auto_domain:
                    # Lower confidence for known platforms
                    if gt_domain in ['facebook.com', 'instagram.com', 'twitter.com', 'linkedin.com']:
                        match_level = 'domain_platform'
                        confidence = 20
                    else:
                        match_level = 'domain_only'
                        confidence = 40
                else:
                    match_level = 'no_match'
                    confidence = 0

                # Calculate combined similarity score
                combined_similarity = (url_similarity * 0.7 + token_similarity * 0.3) * 100

                # Only include if meets minimum similarity
                if combined_similarity >= min_similarity or confidence > 0:
                    results.append({
                        'ground_truth_id': gt_row['ground_truth_id'],
                        'city': gt_city,
                        'search_language': gt_row['search_language'],
                        'gt_url': gt_row['source_url'],
                        'gt_url_norm': gt_url,
                        'automation_id': auto_row['automation_id'],
                        'run_id': auto_row['run_id'],
                        'version': auto_row['version'],
                        'auto_url': auto_row['source_url'],
                        'auto_url_norm': auto_url,
                        'is_included': auto_row['is_included_bool'],
                        'match_level': match_level,
                        'confidence_score': confidence,
                        'url_similarity_pct': round(url_similarity * 100, 2),
                        'token_similarity_pct': round(token_similarity * 100, 2),
                        'combined_similarity_pct': round(combined_similarity, 2),
                        'review_action': 'AUTO_ACCEPT' if confidence == 100 else 'MANUAL_REVIEW'
                    })

            if (idx + 1) % 10 == 0:
                print(f"  Processed {idx + 1}/{len(gt)} ground truth URLs...")

        df = pd.DataFrame(results)

        if len(df) > 0:
            # Sort by ground truth ID and similarity scores
            df = df.sort_values(
                ['ground_truth_id', 'confidence_score', 'combined_similarity_pct'],
                ascending=[True, False, False]
            )

        print(f"\nFound {len(df)} potential matches")
        return df

    def generate_review_report(self, output_dir='reports', min_similarity=30.0):
        """Generate manual review report with similarity scores"""
        output_dir = Path(output_dir)
        output_dir.mkdir(exist_ok=True)

        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        # Find all similar URLs
        print("\n" + "="*80)
        print("SIMILARITY-BASED MATCHING ANALYSIS")
        print("="*80)

        matches_df = self.find_similar_urls(min_similarity=min_similarity)

        if len(matches_df) == 0:
            print("No matches found!")
            return

        # Save full results
        full_report_path = output_dir / f'similarity_matches_full_{timestamp}.csv'
        matches_df.to_csv(full_report_path, index=False)
        print(f"\nFull matches saved: {full_report_path}")

        # Generate manual review queue
        review_queue = matches_df[
            matches_df['review_action'] == 'MANUAL_REVIEW'
        ].copy()

        review_path = output_dir / f'manual_review_queue_{timestamp}.csv'
        review_queue.to_csv(review_path, index=False)
        print(f"Manual review queue saved: {review_path}")
        print(f"  Total items for review: {len(review_queue)}")

        # Generate summary statistics
        summary_path = output_dir / f'similarity_summary_{timestamp}.txt'

        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write("="*80 + "\n")
            f.write("SIMILARITY MATCHING SUMMARY\n")
            f.write("="*80 + "\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")

            # Overall stats
            total_gt = len(self.ground_truth)
            matched_gt = matches_df['ground_truth_id'].nunique()

            f.write(f"Total Ground Truth URLs: {total_gt}\n")
            f.write(f"Matched URLs (any level): {matched_gt}\n")
            f.write(f"Match Rate: {round(matched_gt / total_gt * 100, 2)}%\n\n")

            # By match level
            f.write("MATCHES BY CONFIDENCE LEVEL\n")
            f.write("-"*80 + "\n")
            level_stats = matches_df.groupby('match_level').agg({
                'ground_truth_id': 'nunique',
                'confidence_score': 'first'
            }).sort_values('confidence_score', ascending=False)
            f.write(level_stats.to_string())
            f.write("\n\n")

            # By city
            f.write("MATCHES BY CITY\n")
            f.write("-"*80 + "\n")
            city_stats = matches_df.groupby('city').agg({
                'ground_truth_id': 'nunique',
                'combined_similarity_pct': 'mean'
            }).round(2)
            f.write(city_stats.to_string())
            f.write("\n\n")

            # High similarity matches (>80%)
            high_sim = matches_df[matches_df['combined_similarity_pct'] >= 80]
            f.write(f"HIGH SIMILARITY MATCHES (>=80%)\n")
            f.write("-"*80 + "\n")
            f.write(f"Count: {len(high_sim)}\n\n")
            if len(high_sim) > 0:
                f.write(high_sim[['ground_truth_id', 'gt_url', 'auto_url', 'combined_similarity_pct']].head(20).to_string(index=False))
            f.write("\n\n")

        print(f"Summary report saved: {summary_path}")
        print("\nAnalysis complete!")


def main():
    """Main execution function"""
    print("="*80)
    print("CULTIVATE Similarity-Based URL Matching")
    print("="*80)
    print()

    analyzer = SimilarityAnalyzer(data_dir='data')
    analyzer.load_data()

    # Generate review report with 30% minimum similarity
    analyzer.generate_review_report(output_dir='reports', min_similarity=30.0)

    print("\n" + "="*80)
    print("Analysis complete!")
    print("="*80)


if __name__ == '__main__':
    main()
