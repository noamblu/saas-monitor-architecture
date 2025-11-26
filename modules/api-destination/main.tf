resource "aws_cloudwatch_event_connection" "this" {
  name               = "${var.name}-connection"
  authorization_type = var.auth_type

  auth_parameters {
    # API Key
    dynamic "api_key" {
      for_each = var.auth_type == "API_KEY" && var.api_key != null ? [var.api_key] : []
      content {
        key   = api_key.value.key
        value = api_key.value.value
      }
    }

    # Basic Auth
    dynamic "basic" {
      for_each = var.auth_type == "BASIC" && var.basic_auth != null ? [var.basic_auth] : []
      content {
        username = basic.value.username
        password = basic.value.password
      }
    }

    # OAuth
    dynamic "oauth" {
      for_each = var.auth_type == "OAUTH" && var.oauth != null ? [var.oauth] : []
      content {
        authorization_endpoint = oauth.value.authorization_endpoint
        http_method            = oauth.value.http_method

        client_parameters {
          client_id     = oauth.value.client_parameters.client_id
          client_secret = oauth.value.client_parameters.client_secret
        }

        dynamic "oauth_http_parameters" {
          for_each = oauth.value.oauth_http_parameters != null ? [oauth.value.oauth_http_parameters] : []
          content {
            # Header Parameters
            dynamic "header" {
              for_each = oauth_http_parameters.value.header != null ? oauth_http_parameters.value.header : []
              content {
                key             = header.value.key
                value           = header.value.value
                is_value_secret = header.value.is_value_secret
              }
            }

            # Body Parameters
            dynamic "body" {
              for_each = oauth_http_parameters.value.body != null ? oauth_http_parameters.value.body : []
              content {
                key             = body.value.key
                value           = body.value.value
                is_value_secret = body.value.is_value_secret
              }
            }

            # Query String Parameters
            dynamic "query_string" {
              for_each = oauth_http_parameters.value.query_string != null ? oauth_http_parameters.value.query_string : []
              content {
                key             = query_string.value.key
                value           = query_string.value.value
                is_value_secret = query_string.value.is_value_secret
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_cloudwatch_event_api_destination" "this" {
  name                = "${var.name}-destination"
  invocation_endpoint = var.invocation_endpoint
  http_method         = var.http_method
  connection_arn      = aws_cloudwatch_event_connection.this.arn
}
