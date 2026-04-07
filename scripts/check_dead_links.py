import boto3
import requests
from concurrent.futures import ThresholdExecutor

BUCKET = "cultivate-mapping-data"
RUN01_PREFIX = "raw/automation/run-01/"
OUTPUT_KEY = "raw/exploration_data/2026_data/04_SHARECITY100/dead_link_report.csv"

s3 = boto3.client("s3", region_name="eu-north-1")

SHARECITY100_PRIORITY4 = [
    "Nairobi", "Dakar", "Johannesburg",
    "Beijing", "Shanghai", "Hong Kong", "Bangalore", "Chennai", "Mumbai",
    "Jakarta", "Tel Aviv", "Tokyo", "Toyama", "Kuala Lumpur", "Manila",
    "Doha", "Singapore", "Seoul", "Dubai",
    "Amsterdam", "Berlin", "Brussels", "Bucharest", "Cologne", "Copenhagen",
    "Frankfurt", "Gothenburg", "Madrid", "Naples", "Nijmegen", "Paris",
    "Prague", "Rome", "Rotterdam", "Stockholm", "Thessaloniki", "Vienna", "Warsaw",
    "Birmingham", "Istanbul", "London", "Moscow", "Zürich",
    "Elora, Ontario", "Montreal", "Toronto", "Vancouver", "Mexico City",
    "Ann Arbor, Michigan", "Asheville, North Carolina", "Atlanta", "Austin, Texas",
    "Berkeley, California", "Bloomington, Indiana", "Boston", "Boulder, Colorado",
    "Chicago", "Cleveland", "Dallas", "Denver", "Detroit", "Gulfport/Biloxi",
    "Hartford, Connecticut", "Houston", "Ithaca, New York", "Jackson, Mississippi",
    "Long Beach, California", "Los Angeles", "Louisville, Kentucky", "Media, Pennsylvania",
    "New York City", "Oakland, California", "Philadelphia", "Pittsburgh",
    "Portland, Oregon", "Rochester, New York", "San Francisco", "Seattle",
    "St. Louis", "Washington, D.C.",
    "Adelaide", "Canberra", "Melbourne", "Sydney", "Christchurch", "Wellington",
    "Buenos Aires", "Santa Cruz de la Sierra", "Porto Alegre", "Rio de Janeiro",
    "São Paulo", "Santiago", "Bogotá", "Medellín", "Quito",
]

def get_run01_keys():
    response = s3.list_objects_v2(bucket=BUCKET, Prefix=RUN01_PREFIX)
    return [obj["key"] for obj in response.get("Contents", [])]
