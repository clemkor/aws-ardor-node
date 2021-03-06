data "template_file" "image" {
  template = "$${repository_url}:$${tag}"

  vars {
    repository_url = "${data.terraform_remote_state.image_repository.repository_url}"
    tag = "${var.version_number}"
  }
}

data "template_file" "task_container_definitions" {
  template = "${file("${path.root}/container-definitions/ardor.json.tpl")}"

  vars {
    aws_s3_configuration_object = "${data.template_file.env_url.rendered}"

    peer_server_port = "${var.peer_server_port}"
    api_server_port = "${var.api_server_port}"
  }
}

resource "aws_security_group_rule" "peer_server_port" {
  security_group_id = "${data.terraform_remote_state.cluster.security_group_id}"

  type = "ingress"

  from_port = "${var.peer_server_port}"
  to_port = "${var.peer_server_port}"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "api_server_port" {
  security_group_id = "${data.terraform_remote_state.cluster.security_group_id}"

  type = "ingress"

  from_port = "${var.api_server_port}"
  to_port = "${var.api_server_port}"
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

module "service" {
  source = "infrablocks/ecs-service/aws"
  version = "0.1.12"

  region = "${var.region}"
  vpc_id = "${data.terraform_remote_state.network.vpc_id}"

  component = "${var.component}"
  deployment_identifier = "${var.deployment_identifier}"

  service_name = "${var.service_name}"
  service_image = "${data.template_file.image.rendered}"
  service_port = "${var.peer_server_port}"

  service_task_container_definitions = "${data.template_file.task_container_definitions.rendered}"

  service_desired_count = "${var.desired_count}"
  service_deployment_maximum_percent = "${var.deployment_maximum_percent}"
  service_deployment_minimum_healthy_percent = "${var.deployment_minimum_healthy_percent}"

  attach_to_load_balancer= "no"

  service_volumes = [
    {
      name = "ardor-data"
      host_path = "/opt/ardor/nxt_db"
    },
    {
      name = "ardor-certs"
      host_path = "/opt/ardor/nxt_certs"
    }
  ]

  ecs_cluster_id = "${data.terraform_remote_state.cluster.cluster_id}"
  ecs_cluster_service_role_arn = "${data.terraform_remote_state.cluster.service_role_arn}"
}
