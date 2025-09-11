# Pay Log Aggregator

A minimal FastAPI service.

## Quick Start

### Installation

1. Clone the repository:
```bash
git clone git@github.com:togahh/pay-log-aggregator.git
cd pay-log-aggregator
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

### Running the Application

Start the development server:
```bash
python main.py
```

The API will be available at:
- **API**: http://localhost:8000
- **Interactive API docs**: http://localhost:8000/docs

## API Endpoints

- `GET /` - Returns a simple "I'm alive" message and logs to console

## Project Structure

```
├── main.py                 # FastAPI application entry point
├── requirements.txt        # Python dependencies
└── README.md
```
