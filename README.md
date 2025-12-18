# 🧠 Autonomous K-Means Architecture (Matlab)

> **An intelligent clustering system that autonomously determines the optimal number of clusters (K) and selects the best distance metric without human intervention.**

This project goes beyond standard K-Means implementations by introducing an "Agent-Based" decision mechanism. It analyzes the dataset, calculates geometric elbows, validates with Silhouette scores, and simulates the learning process in real-time.

---

## 🚀 Key Features

* **🕵️‍♂️ Agent 1 (K-Scout):**
    * Automatically determines the search range based on data size (`sqrt(N)` rule).
    * Finds the optimal `K` using a hybrid approach: **Geometric Elbow Method** + **Silhouette Analysis**.
* **📐 Agent 2 (Metric-Scout):**
    * Tests multiple geometric topologies: **Euclidean**, **Manhattan**, and **Minkowski**.
    * Autonomously selects the best metric that fits the data distribution.
* **⚡ High Performance:**
    * Includes a **Sampling Mechanism** to handle Big Data sets efficiently in real-time.
* **📊 Live Simulation:**
    * Visualizes the convergence process and centroid movements step-by-step.
* **📈 Automated Reporting:**
    * Exports final results to Excel and provides statistical distribution analysis.

---

## 🛠️ How It Works (The Algorithm)

1.  **Data Ingestion:** Loads real-world data (e.g., Driver Behaviors) and applies **Min-Max Normalization**.
2.  **Phase 1 (K-Selection):** The system scans possible cluster counts and identifies the "Elbow" point mathematically.
3.  **Phase 2 (Topology Check):** It runs a contest between distance metrics (Euclidean vs. Manhattan) to maximize cluster separation.
4.  **Phase 3 (Execution):** The final model runs with the optimized parameters and visualizes the results.

---

## 📷 Screenshots

| K-Selection Agent | Live Simulation |
| ----------------- | --------------- |
| ![K-Select](url-to-your-screenshot-1.png) | ![Simulation](url-to-your-screenshot-2.png) |

*(Not: Ekran görüntülerini yükleyip linklerini buraya koyarsın)*

## 📂 Dataset
The project uses the `driver-data.csv` dataset, which contains:
* **Distance Feature:** Mean distance driven per day.
* **Speeding Feature:** Mean percentage of time driven over the speed limit.

## 👨‍💻 Author
**[Senin Adın]** - Computer Engineering Student
