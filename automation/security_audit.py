from kubernetes import client, config

# Load kubeconfig
config.load_kube_config()

v1 = client.CoreV1Api()

namespaces = ["boutique"]

print("\nStarting Kubernetes Security Audit\n")

for ns in namespaces:
    print(f"\nNamespace: {ns}\n")

    pods = v1.list_namespaced_pod(ns)

    for pod in pods.items:
        pod_name = pod.metadata.name

        for container in pod.spec.containers:

            cname = container.name

            # 1️ Check if running as root
            sc = container.security_context
            if sc is None or sc.run_as_non_root is not True:
                print(f"{pod_name}/{cname} → container may run as ROOT")

            # 2️ Check privileged containers
            if sc and sc.privileged:
                print(f"{pod_name}/{cname} → PRIVILEGED container detected")

            # 3️ Check resource limits
            if not container.resources or not container.resources.limits:
                print(f"{pod_name}/{cname} → missing resource limits")

            # 4️ Check liveness probe
            if not container.liveness_probe:
                print(f"{pod_name}/{cname} → missing liveness probe")

            # 5️ Check readiness probe
            if not container.readiness_probe:
                print(f"{pod_name}/{cname} → missing readiness probe")

print("\nSecurity audit complete\n")