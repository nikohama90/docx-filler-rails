# DOCX Placeholder Filler

Rails 8 + Docker + Postgres app that:
- Uploads a .docx template
- Detects {{PLACEHOLDER}} fields dynamically
- Generates a filled .docx document

## Run

docker compose up --build