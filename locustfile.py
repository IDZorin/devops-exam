from locust import HttpUser, task, between


class LoadTestingUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def healthcheck(self):
        self.client.get("/health")

    @task(1)
    def predict_iris(self):
        payload = {
            "sepal_length": 5.1,
            "sepal_width": 3.5,
            "petal_length": 1.4,
            "petal_width": 0.2,
        }
        self.client.post("/predict", json=payload)
