from flask import Flask, render_template, request
import joblib
import numpy as np
import os

# -----------------------------------
# Initialize Flask App
# -----------------------------------
app = Flask(__name__)

# -----------------------------------
# Load Trained Model
# -----------------------------------
MODEL_PATH = "random_forest_churn.pkl"

if not os.path.exists(MODEL_PATH):
    raise FileNotFoundError("Model file not found!")

model = joblib.load(MODEL_PATH)

# -----------------------------------
# Home Route
# -----------------------------------
@app.route("/")
def home():
    return render_template("index.html")


# -----------------------------------
# Prediction Route
# -----------------------------------
@app.route("/predict", methods=["POST"])
def predict():
    try:
        # Collect form inputs
        total_orders = float(request.form["total_orders"])
        total_revenue = float(request.form["total_revenue"])
        avg_order_value = float(request.form["avg_order_value"])
        age = float(request.form["age"])
        gender = float(request.form["gender"])  # 0 = Female, 1 = Male

        # Create feature array (Must match training order)
        features = np.array([[total_orders,
                              total_revenue,
                              avg_order_value,
                              age,
                              gender]])

        # Prediction
        prediction = model.predict(features)[0]
        probability = model.predict_proba(features)[0][1]
        prob_percent = round(probability * 100, 2)

        # -----------------------------
        # Risk Categorization Logic
        # -----------------------------
        if prob_percent >= 70:
            risk_level = "High Risk 🔴"
            recommended_action = """
            1. Offer instant 30% discount coupon.
            2. Send personalized push notification.
            3. Provide free delivery for next 3 orders.
            4. Assign loyalty bonus points.
            """
        elif prob_percent >= 40:
            risk_level = "Medium Risk 🟠"
            recommended_action = """
            1. Send 15% discount campaign.
            2. Recommend favorite cuisines.
            3. Notify about trending restaurants.
            4. Provide limited-time offers.
            """
        else:
            risk_level = "Low Risk 🟢"
            recommended_action = """
            1. Maintain engagement with reward points.
            2. Promote premium memberships.
            3. Suggest subscription plans (Swiggy One).
            4. Send referral incentives.
            """

        return render_template(
            "result.html",
            probability=prob_percent,
            risk_level=risk_level,
            recommended_action=recommended_action
        )

    except Exception as e:
        return render_template(
            "result.html",
            probability="Error",
            risk_level="Error",
            recommended_action=str(e)
        )


# -----------------------------------
# Run Local Development Server
# -----------------------------------
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)