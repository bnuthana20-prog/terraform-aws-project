from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "<h1>Deployed via Terraform + Docker + CI/CD</h1><p>Project by bnuth</p><p>Status: Running on EC2 behind ALB</p>"

@app.route('/health')
def health():
    return "OK - Healthy"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
