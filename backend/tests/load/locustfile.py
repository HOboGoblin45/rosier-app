"""
Locust load testing configuration for Rosier API.

Simulates realistic user behavior patterns with multiple user classes
representing different usage patterns in the application.
"""

import random
import json
from locust import HttpUser, task, between, TaskSet, events
from locust.contrib.fasthttp import FastHttpUser


class CardSwipeData:
    """Helper class to manage card/product data for swipes."""

    def __init__(self):
        self.card_ids = list(range(1, 1000))  # Simulate 1000 available cards
        random.shuffle(self.card_ids)
        self.current_index = 0

    def get_next_card(self):
        """Get next card ID in rotation."""
        if self.current_index >= len(self.card_ids):
            random.shuffle(self.card_ids)
            self.current_index = 0

        card_id = self.card_ids[self.current_index]
        self.current_index += 1
        return card_id


class RosierTaskSet(TaskSet):
    """Base task set with common functionality."""

    def on_start(self):
        """Initialize user session."""
        self.card_data = CardSwipeData()
        self.user_id = None
        self.authenticated = False
        self.dresser_items = []

    def login_user(self):
        """Authenticate user with email."""
        email = f"loadtest_{self.locust_request_meta['msg_prefix']}_{random.randint(1000, 99999)}@rosier.app"
        password = "LoadTest2026!"

        response = self.client.post(
            "/auth/email/login",
            json={"email": email, "password": password},
            catch_response=True,
        )

        if response.status_code == 200:
            data = response.json()
            self.user_id = data.get("user_id")
            self.authenticated = True
            response.success()
        else:
            response.failure(f"Login failed with status {response.status_code}")

    def get_next_card(self):
        """Get next card for swiping."""
        if not self.authenticated:
            return None
        return self.card_data.get_next_card()

    def record_swipe(self, card_id, action):
        """Record a card swipe/interaction."""
        if not self.authenticated:
            return

        payload = {
            "card_id": card_id,
            "action": action,  # "like", "pass", "save"
            "duration_ms": random.randint(500, 5000),
        }

        self.client.post(
            "/cards/events",
            json=payload,
            name="/cards/events [swipe]",
        )

        if action == "like":
            self.dresser_items.append(card_id)


class NewUserFlow(RosierTaskSet):
    """Simulates new user onboarding flow."""

    wait_time = between(2, 5)

    def on_start(self):
        """Initialize new user flow."""
        super().on_start()
        self.quiz_completed = False

    @task
    def complete_onboarding_quiz(self):
        """Complete style quiz during onboarding."""
        if self.quiz_completed:
            return

        quiz_responses = {
            "aesthetic_preference": random.choice(
                [
                    "minimalist",
                    "maximalist",
                    "bohemian",
                    "contemporary",
                    "vintage",
                ]
            ),
            "favorite_colors": random.sample(
                ["black", "white", "navy", "cream", "earth"],
                k=2,
            ),
            "brand_affinity": random.choice(
                ["luxury", "indie", "sustainable", "high_street", "mixed"]
            ),
            "budget_range": random.choice(
                ["under_100", "100_250", "250_500", "500_plus"]
            ),
            "body_type": random.choice(
                ["petite", "pear", "hourglass", "rectangle", "apple"]
            ),
        }

        self.client.post(
            "/onboarding/quiz",
            json=quiz_responses,
            name="/onboarding/quiz",
        )

        self.quiz_completed = True

    @task
    def login(self):
        """Login user."""
        if not self.authenticated:
            self.login_user()

    @task(weight=3)
    def swipe_cards(self):
        """Swipe through product cards."""
        if not self.authenticated:
            return

        card_id = self.get_next_card()
        if card_id:
            action = random.choice(["like", "pass", "pass", "like"])
            self.record_swipe(card_id, action)

    @task
    def create_dresser(self):
        """Create or add to dresser after liking items."""
        if not self.authenticated or not self.dresser_items:
            return

        for item_id in self.dresser_items[:5]:
            self.client.post(
                "/dresser/items",
                json={
                    "product_id": item_id,
                    "category": random.choice(["shoes", "bags", "accessories"]),
                },
                name="/dresser/items",
            )

    @task
    def view_dresser(self):
        """View saved dresser items."""
        if not self.authenticated:
            return

        self.client.get("/dresser", name="/dresser")

    @task
    def click_affiliate_link(self):
        """Click affiliate link to shop."""
        if not self.authenticated or not self.dresser_items:
            return

        item_id = random.choice(self.dresser_items)
        self.client.get(
            f"/products/{item_id}/affiliate_link",
            name="/products/{id}/affiliate_link",
        )


class ActiveUserFlow(RosierTaskSet):
    """Simulates regular/active user behavior."""

    wait_time = between(1, 3)

    @task
    def login(self):
        """Login user at session start."""
        if not self.authenticated:
            self.login_user()

    @task(weight=4)
    def swipe_cards_batch(self):
        """Batch swipe through multiple cards."""
        if not self.authenticated:
            return

        for _ in range(random.randint(5, 15)):
            card_id = self.get_next_card()
            if card_id:
                action = random.choices(
                    ["like", "pass"],
                    weights=[25, 75],
                    k=1,
                )[0]
                self.record_swipe(card_id, action)

    @task(weight=2)
    def batch_swipe_events(self):
        """Send batched swipe events."""
        if not self.authenticated:
            return

        events = [
            {
                "card_id": self.get_next_card(),
                "action": random.choices(
                    ["like", "pass"],
                    weights=[25, 75],
                    k=1,
                )[0],
                "duration_ms": random.randint(500, 5000),
            }
            for _ in range(random.randint(10, 30))
        ]

        self.client.post(
            "/cards/events/batch",
            json={"events": events},
            name="/cards/events/batch",
        )

    @task
    def view_dresser(self):
        """Check saved dresser."""
        if not self.authenticated:
            return

        self.client.get("/dresser", name="/dresser")

    @task
    def get_daily_drop(self):
        """Check for new daily drops."""
        if not self.authenticated:
            return

        self.client.get(
            "/products/daily-drop",
            name="/products/daily-drop",
        )

    @task
    def view_product_details(self):
        """View specific product details."""
        if not self.authenticated:
            return

        product_id = self.get_next_card()
        self.client.get(
            f"/products/{product_id}",
            name="/products/{id}",
            timeout=5,
        )

    @task(weight=2)
    def click_shop_links(self):
        """Click affiliate links to shop."""
        if not self.authenticated:
            return

        for _ in range(random.randint(1, 3)):
            product_id = self.get_next_card()
            self.client.get(
                f"/products/{product_id}/affiliate_link",
                name="/products/{id}/affiliate_link",
            )


class PowerUserFlow(RosierTaskSet):
    """Simulates highly engaged power users."""

    wait_time = between(0.5, 2)

    @task
    def login(self):
        """Login user."""
        if not self.authenticated:
            self.login_user()

    @task(weight=3)
    def aggressive_swiping(self):
        """Power users swipe many cards per session."""
        if not self.authenticated:
            return

        for _ in range(random.randint(20, 50)):
            card_id = self.get_next_card()
            if card_id:
                action = random.choices(
                    ["like", "pass"],
                    weights=[30, 70],
                    k=1,
                )[0]
                self.record_swipe(card_id, action)

    @task
    def check_profile(self):
        """Check profile and Style DNA."""
        if not self.authenticated:
            return

        self.client.get(
            "/profile/style_dna",
            name="/profile/style_dna",
        )

    @task
    def organize_dresser(self):
        """Organize and manage dresser items."""
        if not self.authenticated or not self.dresser_items:
            return

        # Get dresser
        self.client.get("/dresser", name="/dresser")

        # Reorganize some items
        for item_id in random.sample(
            self.dresser_items,
            k=min(5, len(self.dresser_items)),
        ):
            self.client.put(
                f"/dresser/items/{item_id}",
                json={"category": random.choice(["shoes", "bags", "accessories"])},
                name="/dresser/items/{id} [update]",
            )

    @task
    def share_style_dna(self):
        """Share Style DNA profile."""
        if not self.authenticated:
            return

        self.client.post(
            "/profile/style_dna/share",
            json={
                "share_type": random.choice(["link", "social"]),
                "platforms": random.sample(["instagram", "twitter", "tiktok"], k=1),
            },
            name="/profile/style_dna/share",
        )

    @task(weight=2)
    def multiple_shop_clicks(self):
        """Power users click multiple shop links."""
        if not self.authenticated:
            return

        for _ in range(random.randint(3, 8)):
            product_id = self.get_next_card()
            self.client.get(
                f"/products/{product_id}/affiliate_link",
                name="/products/{id}/affiliate_link",
            )

    @task
    def get_recommendations(self):
        """Get personalized recommendations."""
        if not self.authenticated:
            return

        self.client.get(
            "/recommendations/personalized",
            name="/recommendations/personalized",
        )


class RosierUser(FastHttpUser):
    """Main Locust user class combining all task sets."""

    tasks = {
        NewUserFlow: 20,  # 20% new users
        ActiveUserFlow: 60,  # 60% active users
        PowerUserFlow: 20,  # 20% power users
    }

    wait_time = between(1, 5)

    def on_start(self):
        """Initialize user."""
        self.locust_request_meta = {"msg_prefix": random.randint(10000, 99999)}


# Event handlers for detailed logging
@events.request.add_listener
def log_request_stats(request_type, name, response_time, response_length, response,
                      context, exception, **kwargs):
    """Log request statistics."""
    if exception:
        print(f"Request failed: {name} - {exception}")
    else:
        print(
            f"{request_type} {name}: {response_time}ms - "
            f"Status: {response.status_code}"
        )


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Log test start."""
    print("\n=== Load Test Started ===")
    print(f"Target: {environment.host}")
    print(f"Expected concurrent users: {environment.runner.target_user_count}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Log test completion and statistics."""
    print("\n=== Load Test Completed ===")

    if environment.stats.total.num_requests > 0:
        print(f"Total requests: {environment.stats.total.num_requests}")
        print(f"Failures: {environment.stats.total.num_failures}")
        print(f"Avg response time: {environment.stats.total.avg_response_time:.2f}ms")
        print(f"Median response time: {environment.stats.total.get_response_time_percentile(0.5):.2f}ms")
        print(f"95th percentile: {environment.stats.total.get_response_time_percentile(0.95):.2f}ms")
        print(f"99th percentile: {environment.stats.total.get_response_time_percentile(0.99):.2f}ms")
        print(f"Min response time: {environment.stats.total.min_response_time:.2f}ms")
        print(f"Max response time: {environment.stats.total.max_response_time:.2f}ms")


# Performance targets for validation
PERFORMANCE_TARGETS = {
    "/cards/next": {"p95": 200, "p99": 500},  # milliseconds
    "/cards/events": {"p95": 100, "p99": 300},
    "/dresser": {"p95": 300, "p99": 500},
    "/products/{id}": {"p95": 250, "p99": 500},
    "/affiliate_link": {"p95": 200, "p99": 500},
}

# Error rate target: < 1%
ERROR_RATE_TARGET = 0.01

# Concurrent users to support: 10,000
TARGET_CONCURRENT_USERS = 10000
