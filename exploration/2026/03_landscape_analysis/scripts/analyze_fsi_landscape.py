#!/usr/bin/env python3
"""
FSI Landscape Analysis Script
Analyzes final deduplicated FSI data from Gold layer
Generates statistics for 105 cities report
"""

import json
from collections import Counter, defaultdict
from pathlib import Path
import csv

# Paths
GOLD_DATA = Path("data/gold/CopyCultivateAPItoBlob")
OUTPUT_DIR = Path("reports/2026_03_fsi_landscape")

# Regional clusters (based on original report)
REGIONAL_CLUSTERS = {
    # Southern Europe
    'Barcelona': 'Southern Europe',
    'Milan': 'Southern Europe',
    'Bari': 'Southern Europe',
    'Seville': 'Southern Europe',
    'Ljubljana': 'Southern Europe',
    'Athens': 'Southern Europe',
    'Turin': 'Southern Europe',
    'Marseille': 'Southern Europe',

    # Western Europe
    'Utrecht': 'Western Europe',
    'Bordeaux': 'Western Europe',
    'Lyon': 'Western Europe',
    'Dublin': 'Western Europe',
    'Nantes': 'Western Europe',
    'Brighton and Hove': 'Western Europe',
    'Dresden': 'Western Europe',
    'Antwerp': 'Western Europe',
    'Liege': 'Western Europe',
    'Cork': 'Western Europe',
    'Graz': 'Western Europe',
    'Innsbruck': 'Western Europe',

    # Northern Europe
    'Copenhagen': 'Northern Europe',
    'Oslo': 'Northern Europe',
    'Stockholm': 'Northern Europe',
    'Helsinki': 'Northern Europe',

    # Eastern Europe
    'Brno': 'Eastern Europe',
    'Warsaw': 'Eastern Europe',
    'Prague': 'Eastern Europe',
    'Budapest': 'Eastern Europe',
    'Kyiv': 'Eastern Europe',

    # Other / Neighbourhood
    'Auckland': 'Other / Neighbourhood',
    'Jerusalem': 'Other / Neighbourhood',
    'Rabat': 'Other / Neighbourhood',
    'Tbilisi': 'Other / Neighbourhood',
    'Tunis': 'Other / Neighbourhood',
    'Yerevan': 'Other / Neighbourhood',
    'Ankara': 'Other / Neighbourhood',
}

# Population data (from original report - you may need to update these)
CITY_POPULATIONS = {
    'Barcelona': 1385000,
    'Utrecht': 345000,
    'Milan': 1243000,
    'Bordeaux': 258000,
    'Turin': 803000,
    'Lyon': 510000,
    'Dublin': 1074000,
    'Nantes': 320000,
    'Brighton and Hove': 290000,
    'Marseille': 820000,
    'Dresden': 550000,
    'Bari': 320000,
    'Seville': 660000,
    'Antwerp': 520000,
    'Liege': 195000,
    'Cork': 220000,
    'Graz': 290000,
    'Auckland': 1400000,
    'Innsbruck': 135000,
    'Brno': 380000,
    'Ljubljana': 295000,
    # Add more cities as needed
}


def load_gold_data():
    """Load deduplicated FSI data from gold layer"""
    with open(GOLD_DATA, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    return data['data']


def analyze_activities(fsis):
    """Analyze food sharing activities"""
    activity_counter = Counter()
    for fsi in fsis:
        activities = fsi.get('foodSharingActivities', [])
        for activity in activities:
            activity_counter[activity] += 1
    return activity_counter


def analyze_sharing_modes(fsis):
    """Analyze how food is shared"""
    mode_counter = Counter()
    for fsi in fsis:
        modes = fsi.get('howItIsShared', [])
        for mode in modes:
            mode_counter[mode] += 1
    return mode_counter


def analyze_by_city(fsis):
    """Group FSIs by city and calculate statistics"""
    city_data = defaultdict(list)

    for fsi in fsis:
        city = fsi.get('city', 'Unknown')
        city_data[city].append(fsi)

    # Calculate statistics per city
    city_stats = []
    for city, city_fsis in city_data.items():
        population = CITY_POPULATIONS.get(city, 0)
        fsi_count = len(city_fsis)
        fsis_per_100k = (fsi_count / population * 100000) if population > 0 else 0

        cluster = REGIONAL_CLUSTERS.get(city, 'Unknown')

        city_stats.append({
            'city': city,
            'country': city_fsis[0].get('country', 'Unknown'),
            'fsi_count': fsi_count,
            'population': population,
            'fsis_per_100k': round(fsis_per_100k, 2),
            'cluster': cluster
        })

    # Sort by FSI count descending
    city_stats.sort(key=lambda x: x['fsi_count'], reverse=True)

    return city_stats


def analyze_by_cluster(city_stats):
    """Analyze FSIs by regional cluster"""
    cluster_data = defaultdict(lambda: {'fsis': 0, 'population': 0, 'cities': 0})

    for city in city_stats:
        cluster = city['cluster']
        cluster_data[cluster]['fsis'] += city['fsi_count']
        cluster_data[cluster]['population'] += city['population']
        cluster_data[cluster]['cities'] += 1

    # Calculate FSIs per 100k for each cluster
    cluster_stats = []
    for cluster, data in cluster_data.items():
        if data['population'] > 0:
            fsis_per_100k = data['fsis'] / data['population'] * 100000
        else:
            fsis_per_100k = 0

        cluster_stats.append({
            'cluster': cluster,
            'total_fsis': data['fsis'],
            'total_population': data['population'],
            'num_cities': data['cities'],
            'fsis_per_100k': round(fsis_per_100k, 2)
        })

    cluster_stats.sort(key=lambda x: x['fsis_per_100k'], reverse=True)

    return cluster_stats


def calculate_multiple_activities(fsis):
    """Calculate how many FSIs have multiple activities"""
    single_activity = 0
    multiple_activities = 0

    for fsi in fsis:
        activities = fsi.get('foodSharingActivities', [])
        if len(activities) == 1:
            single_activity += 1
        elif len(activities) > 1:
            multiple_activities += 1

    return {
        'single_activity': single_activity,
        'multiple_activities': multiple_activities,
        'pct_multiple': round(multiple_activities / len(fsis) * 100, 2) if fsis else 0
    }


def generate_report(fsis):
    """Generate comprehensive analysis report"""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    print("="*80)
    print("FSI LANDSCAPE ANALYSIS - FINAL DEDUPLICATED DATA")
    print("="*80)
    print()

    # Overall statistics
    total_fsis = len(fsis)
    print(f"Total FSIs: {total_fsis}")
    print()

    # Activity analysis
    print("FOOD SHARING ACTIVITIES")
    print("-"*40)
    activities = analyze_activities(fsis)
    for activity, count in activities.most_common():
        pct = count / total_fsis * 100
        print(f"  {activity}: {count} ({pct:.1f}%)")
    print()

    # Sharing modes
    print("HOW FOOD IS SHARED")
    print("-"*40)
    modes = analyze_sharing_modes(fsis)
    for mode, count in modes.most_common():
        pct = count / total_fsis * 100
        print(f"  {mode}: {count} ({pct:.1f}%)")
    print()

    # Multiple activities
    multi_activity = calculate_multiple_activities(fsis)
    print("MULTIPLE ACTIVITIES")
    print("-"*40)
    print(f"  Single activity: {multi_activity['single_activity']}")
    print(f"  Multiple activities: {multi_activity['multiple_activities']} ({multi_activity['pct_multiple']}%)")
    print()

    # City analysis
    print("TOP 20 CITIES BY FSI COUNT")
    print("-"*40)
    city_stats = analyze_by_city(fsis)
    print(f"{'City':<25} {'FSIs':<8} {'Per 100k':<10} {'Cluster':<20}")
    print("-"*70)
    for city in city_stats[:20]:
        print(f"{city['city']:<25} {city['fsi_count']:<8} {city['fsis_per_100k']:<10.2f} {city['cluster']:<20}")
    print()

    # Cluster analysis
    print("REGIONAL CLUSTER ANALYSIS")
    print("-"*40)
    cluster_stats = analyze_by_cluster(city_stats)
    print(f"{'Cluster':<25} {'FSIs':<8} {'Cities':<8} {'FSIs/100k':<10}")
    print("-"*60)
    for cluster in cluster_stats:
        print(f"{cluster['cluster']:<25} {cluster['total_fsis']:<8} {cluster['num_cities']:<8} {cluster['fsis_per_100k']:<10.2f}")
    print()

    # Save detailed city data to CSV
    csv_file = OUTPUT_DIR / "city_statistics.csv"
    with open(csv_file, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['city', 'country', 'fsi_count', 'population', 'fsis_per_100k', 'cluster']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(city_stats)

    print(f"✓ Detailed city statistics saved to: {csv_file}")

    # Save cluster data to CSV
    csv_file = OUTPUT_DIR / "cluster_statistics.csv"
    with open(csv_file, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['cluster', 'total_fsis', 'num_cities', 'total_population', 'fsis_per_100k']
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(cluster_stats)

    print(f"✓ Cluster statistics saved to: {csv_file}")
    print()
    print("="*80)
    print("ANALYSIS COMPLETE")
    print("="*80)


if __name__ == "__main__":
    print("Loading deduplicated FSI data from gold layer...")
    fsis = load_gold_data()
    print(f"Loaded {len(fsis)} FSIs")
    print()

    generate_report(fsis)
