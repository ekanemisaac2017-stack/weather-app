# ----------------------------
# CloudWatch Log Group
# ----------------------------
resource "aws_cloudwatch_log_group" "weather" {
  name              = "/ecs/weather-app"
  retention_in_days = 7
}

# ----------------------------
# ECS Task Definition
# ----------------------------
resource "aws_ecs_task_definition" "weather_task" {
  family                   = "weather-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "weather-app"
      image     = "238851097968.dkr.ecr.us-east-1.amazonaws.com/weather-app:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      # ----------------------------
      # HEALTH + LOGGING SUPPORT
      # ----------------------------
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/weather-app"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }

      # ----------------------------
      # ENVIRONMENT VARIABLES
      # ----------------------------
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        }
      ]

      # ----------------------------
      # OPTIONAL: better ECS stability
      # ----------------------------
      stopTimeout = 30
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.weather
  ]
}

resource "aws_ecs_cluster" "main" {
  name = "weather-cluster"
}

resource "aws_ecs_service" "weather_service" {
  name            = "weather-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.weather_task.arn

  launch_type   = "FARGATE"
  desired_count = 1

  # 🔥 IMPORTANT: prevents ALB killing task too early
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = [
      aws_subnet.public_1.id,
      aws_subnet.public_2.id
    ]

    security_groups  = [aws_security_group.ecs_sg.id]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.weather_tg.arn
    container_name   = "weather-app"
    container_port   = 3000
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  depends_on = [
    aws_lb_listener.http
  ]
}