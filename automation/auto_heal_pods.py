from kubernetes import client, config

namespace = "boutique"

try:
    # Works inside cluster
    config.load_incluster_config()
except:
    # Works locally
    config.load_kube_config()

v1 = client.CoreV1Api()

print("\nChecking pods in namespace:", namespace)

pods = v1.list_namespaced_pod(namespace)

for pod in pods.items:
    name = pod.metadata.name
    status = pod.status.phase

    if status not in ["Running", "Succeeded"]:
        print(f"Pod {name} unhealthy: {status}")

        try:
            v1.delete_namespaced_pod(
                name=name,
                namespace=namespace
            )

            print(f"Restarted {name}")

        except Exception as e:
            print(e)