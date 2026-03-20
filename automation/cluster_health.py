from kubernetes import client, config

config.load_kube_config()

v1 = client.CoreV1Api()

print("Nodes:\n")
nodes = v1.list_node()

for node in nodes.items:
    print(node.metadata.name, node.status.conditions[-1].type)

print("\nPods:\n")

pods = v1.list_pod_for_all_namespaces()

for pod in pods.items:
    print(pod.metadata.namespace, pod.metadata.name, pod.status.phase)