# SDI 4213 Week 7 – Help Desk Docker Compose Exercise

This starter repository contains a working **Service Request Tracker** application. The app can run locally with SQLite, but your Week 7 task is to configure it as a multi-service Docker Compose application using PostgreSQL and Adminer.

## What is already provided
- Streamlit browser UI
- Service request create/list/update functionality
- SQLite fallback for local development
- Automated database tests
- Dockerfile for the web application
- CI workflow
- `.env.example`

## What you must add
- Complete `compose.yaml`
- PostgreSQL `db` service
- named persistent volume
- environment configuration
- Adminer service
- service health/dependency configuration
- screenshot evidence

## Local application test
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
streamlit run app/main.py
```

The local app will use SQLite. Open the URL shown by Streamlit (normally `http://localhost:8501`).

## Tests
```powershell
python -m pytest -v
```

## Week 7
Follow the student assignment in `docs/Week7_Individual_Exercise.docx`.
