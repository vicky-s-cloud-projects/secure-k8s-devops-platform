from kubernetes import client, config

# Load kubeconfig
config.load_kube_config()

v1 = client.CoreV1Api()

namespace = "boutique"

print("\n Checking pods in namespace:", namespace)

pods = v1.list_namespaced_pod(namespace)

for pod in pods.items:
    name = pod.metadata.name
    status = pod.status.phase

    # Detect unhealthy states
    if status not in ["Running", "Succeeded"]:
        print(f"Pod {name} is unhealthy: {status}")

        try:
            print(f"Restarting pod: {name}")
            v1.delete_namespaced_pod(name=name, namespace=namespace)
            print(f"Pod {name} deleted. Kubernetes will recreate it.\n")

        except Exception as e:
            print(f"Failed to restart pod {name}: {e}")