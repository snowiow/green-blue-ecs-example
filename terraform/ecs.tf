data "aws_ecr_repository" "this" {
  name = "snowiow/green-blue-ecs-example"
}

locals {
  container_name = "green-blue-ecs-example"
}

resource "aws_cloudwatch_log_group" "this" {
  name = "example-app"
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.10.0"

  container_name  = "${local.container_name}"
  container_image = "${data.aws_ecr_repository.this.repository_url}:latest"

  port_mappings = [
    {
      containerPort = 80
    },
  ]

  log_options = {
    awslogs-region        = "eu-central-1"
    awslogs-group         = "${aws_cloudwatch_log_group.this.name}"
    awslogs-stream-prefix = "ecs-service"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "example-cluster"
}

data "aws_iam_policy_document" "assume_by_ecs" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = [
      "${data.aws_ecr_repository.this.arn}",
    ]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task_role" {
  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters"]

    resources = ["${aws_ecs_cluster.this.arn}"]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "ecs-example-execution-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_ecs.json}"
}

resource "aws_iam_role_policy" "execution_role" {
  role   = "${aws_iam_role.execution_role.name}"
  policy = "${data.aws_iam_policy_document.execution_role.json}"
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-example-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_ecs.json}"
}

resource "aws_iam_role_policy" "task_role" {
  role   = "${aws_iam_role.task_role.name}"
  policy = "${data.aws_iam_policy_document.task_role.json}"
}

resource "aws_ecs_task_definition" "this" {
  family                   = "green-blue-ecs-example-service"
  container_definitions    = "${module.container_definition.json}"
  execution_role_arn       = "${aws_iam_role.execution_role.arn}"
  task_role_arn            = "${aws_iam_role.task_role.arn}"
  network_mode             = "awsvpc"
  cpu                      = "0.25 vcpu"
  memory                   = "0.5 gb"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_security_group" "ecs" {
  name   = "allow-ecs-traffic"
  vpc_id = "${aws_vpc.this.id}"

  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "this" {
  name            = "example-service"
  task_definition = "${aws_ecs_task_definition.this.id}"
  cluster         = "${aws_ecs_cluster.this.arn}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.this.0.arn}"
    container_name   = "${local.container_name}"
    container_port   = 80
  }

  launch_type   = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets         = ["${aws_subnet.this.*.id}"]
    security_groups = ["${aws_security_group.ecs.id}"]

    assign_public_ip = true
  }

  depends_on = ["aws_lb_listener.this"]
}
