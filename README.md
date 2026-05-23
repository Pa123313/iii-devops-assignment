# Distributed Inferencing Prototype — DevOps Assignment

![AWS](https://img.shields.io/badge/AWS-Deployed-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)
![Python](https://img.shields.io/badge/Python-inference-blue)
![TypeScript](https://img.shields.io/badge/TypeScript-caller-blue)
![iii](https://img.shields.io/badge/iii-v0.12.0-green)

> A distributed worker mesh that runs a small language model (Gemma-3-270M) behind a cross-language RPC system. A Python worker hosts the model; a TypeScript worker fans HTTP requests into that RPC and returns JSON. Both workers run on separate VMs, communicate through the iii engine, and are provisioned entirely with Terraform.

---

## 📸 Demo

### Terraform Deployment
![Terraform Output]<img width="812" height="427" alt="terraform" src="https://github.com/user-attachments/assets/4478fc3d-ce4d-43f6-889a-c43d67ad5277" />


### API Working End-to-End
![Curl Response]<img width="1346" height="263" alt="curl output - 1" src="https://github.com/user-attachments/assets/edeb1cc7-23b9-42ef-93b7-837240e02466" />
<img width="1352" height="425" alt="curl output - 2" src="https://github.com/user-attachments/assets/f2997ccc-9484-4b38-82b5-66391377392b" />


---

## 🏗️ Architecture
Internet
|
[API Gateway VM]
Public IP: 44.211.181.212
|
| AWS Private Subnet
|
[iii Engine VM - 172.31.3.50:49134]
Routes all RPC calls via WebSocket
|─────────────────────────────────┐
|                                 |
[inference-worker VM]           [caller-worker VM]
172.31.13.184                   172.31.1.241
Python / Gemma-3-270M           TypeScript / HTTP
Loads and runs the model        Handles HTTP → RPC

---

## 🖥️ Infrastructure

| VM | Private IP | Public IP | Role | Instance |
|---|---|---|---|---|
| API Gateway | 172.31.6.130 | 44.211.181.212 | Public endpoint | m7i-flex.large |
| iii Engine | 172.31.3.50 | 3.235.137.189 | RPC router | m7i-flex.large |
| Inference Worker | 172.31.13.184 | 13.218.116.16 | Python/Gemma model | m7i-flex.large |
| Caller Worker | 172.31.1.241 | 100.53.240.211 | TypeScript/HTTP | m7i-flex.large |

---

## 📁 Project Structure
iii-devops-assignment/
├── infra/
│   ├── main.tf              # AWS provider config
│   ├── vpc.tf               # VPC, subnets, NAT gateway
│   ├── ec2.tf               # EC2 instances
│   ├── security_groups.tf   # Firewall rules
│   ├── variables.tf         # Input variables
│   └── outputs.tf           # Output IPs
├── workers/
│   ├── inference-worker/
│   │   └── inference_worker.py   # Python/Gemma inference
│   └── caller-worker/
│       └── worker.ts             # TypeScript HTTP handler
└── README.md

---

## ⚡ Quick Start

### 1. Deploy Infrastructure
```bash
cd infra
terraform init
terraform apply
```

### 2. Start Engine VM
```bash
ssh -i iii-key.pem ubuntu@<ENGINE_PUBLIC_IP>
iii --config config.yaml
```

### 3. Start Inference Worker
```bash
ssh -i iii-key.pem ubuntu@<INFERENCE_PUBLIC_IP>
cd workers/inference-worker
python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt
III_URL=ws://172.31.3.50:49134 python3 inference_worker.py
```

### 4. Start Caller Worker
```bash
ssh -i iii-key.pem ubuntu@<CALLER_PUBLIC_IP>
cd workers/caller-worker
npm install
III_URL=ws://172.31.3.50:49134 npx tsx worker.ts
```

---

## 📡 API Reference

**Endpoint:** `POST /v1/chat/completions`

**Request:**
```json
{
  "messages": [
    {"role": "user", "content": "What is 2 + 2?"}
  ]
}
```

**Response:**
```json
{
  "result": {
    "response": "...",
    "success": "You've connected two workers and they're interoperating seamlessly"
  }
}
```

**Curl:**
```bash
curl -X POST http://172.31.3.50:3111/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"messages": [{"role": "user", "content": "What is 2+2?"}]}'
```

---

## 🔄 RPC Flow
curl POST /v1/chat/completions
↓
Engine VM (port 3111)
↓ WebSocket RPC
caller-worker (TypeScript)
→ registers HTTP trigger
→ calls inference::run_inference
↓ WebSocket RPC
inference-worker (Python)
→ loads Gemma-3-270M model
→ runs inference
→ returns result
↓
JSON response back to curl

---

## 🔒 Production Hardening

- Add TLS/HTTPS with AWS ACM + ALB
- Use AWS IAM roles instead of open security groups
- Enable AWS WAF on the API gateway
- Store secrets in AWS Secrets Manager
- Add CloudWatch logging and alerting
- Enable VPC Flow Logs for network monitoring
- Add systemd services for auto-restart on reboot
- Use private subnets with NAT Gateway only

---

## 📈 Scaling for 100x Larger Model

- Use GPU instances (`g4dn.xlarge` or `p3.2xlarge`)
- Store model weights in S3, download on startup
- Run multiple inference-worker replicas behind a load balancer
- Use AWS ECS or Kubernetes for auto-scaling
- Add request queuing with `iii-queue` for high throughput
- Use model quantization and batching for efficiency
- Separate model storage from compute using EFS

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Infrastructure | Terraform, AWS EC2, VPC, Security Groups |
| Engine | iii framework v0.12.0 |
| Inference | Python, HuggingFace Transformers, Gemma-3-270M GGUF |
| API | TypeScript, Node.js, iii-sdk v0.11.0 |
| Protocol | WebSocket RPC |
| OS | Ubuntu 26.04 LTS |
