from kubernetes import client, config
from datetime import datetime

config.load_kube_config()

v1 = client.CoreV1Api()
apps = client.AppsV1Api()

namespace = "boutique"

print("\nKubernetes Deployment Report")
print("--------------------------------")
print("Generated:", datetime.now(), "\n")

# 1️ Node Status
nodes = v1.list_node()

print("Nodes:")
for node in nodes.items:
    name = node.metadata.name
    status = node.status.conditions[-1].type
    print(f" - {name}: {status}")

print("\n")

# 2️ Pod Status
pods = v1.list_namespaced_pod(namespace)

running = 0
failed = 0
pending = 0

for pod in pods.items:
    phase = pod.status.phase

    if phase == "Running":
        running += 1
    elif phase == "Pending":
        pending += 1
    else:
        failed += 1

print("Pods:")
print(" Running:", running)
print(" Pending:", pending)
print(" Failed:", failed)

print("\n")

# 3️ Deployments
deployments = apps.list_namespaced_deployment(namespace)

print("Deployments:")
for dep in deployments.items:
    name = dep.metadata.name
    ready = dep.status.ready_replicas
    replicas = dep.status.replicas

    print(f" - {name}: {ready}/{replicas} ready")

print("\n")

# 4️ Services
services = v1.list_namespaced_service(namespace)

print("Services:")
for svc in services.items:
    print(" -", svc.metadata.name)

print("\n")

print("Report complete\n")