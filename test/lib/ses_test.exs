defmodule ExAws.SESTest do
  use ExUnit.Case, async: true
  alias ExAws.SES

  setup_all do
    {:ok, email: "user@example.com"}
  end

  test "#verify_email_identity", ctx do
    expected = %{"Action" => "VerifyEmailIdentity", "EmailAddress" => ctx.email}
    assert expected == SES.verify_email_identity(ctx.email).params
  end

  test "#verify_email_identity request" do
    resp = SES.verify_email_identity("success@simulator.amazonses.com") |> ExAws.request
    assert {:ok, %{body: %{request_id: _}}} = resp
  end

  test "#identity_verification_attributes", ctx do
    expected = %{
      "Action" => "GetIdentityVerificationAttributes",
      "Identities.member.1" => ctx.email
    }

    assert expected == SES.get_identity_verification_attributes([ctx.email]).params
  end

  test "#configuration_sets" do
    expected = %{"Action" => "ListConfigurationSets", "MaxItems" => 1, "NextToken" => "QUFBQUF"}
    assert expected == SES.list_configuration_sets(max_items: 1, next_token: "QUFBQUF").params
  end

  test "#list_identities" do
    expected = %{"Action" => "ListIdentities", "MaxItems" => 1, "NextToken" => "QUFBQUF", "IdentityType" => "Domain"}
    assert expected == SES.list_identities(max_items: 1, next_token: "QUFBQUF", identity_type: "Domain").params

    expected = %{"Action" => "ListIdentities", "MaxItems" => 1, "NextToken" => "QUFBQUF"}
    assert expected == SES.list_identities(max_items: 1, next_token: "QUFBQUF").params
  end

  describe "#send_email" do
    test "with required params only" do
      dst =  %{to:  ["success@simulator.amazonses.com"]}
      msg = %{body: %{}, subject: %{data: "subject"}}
      expected = %{
        "Action" => "SendEmail", "Destination.ToAddresses.member.1" => "success@simulator.amazonses.com",
        "Message.Subject.Data" => "subject", "Source" => "user@example.com"
      }

      assert expected == SES.send_email(dst, msg, "user@example.com").params
    end

    test "with all optional params" do
      dst =  %{
        bcc: ["success@simulator.amazonses.com"],
        cc:  ["success@simulator.amazonses.com"],
        to:  ["success@simulator.amazonses.com", "bounce@simulator.amazonses.com"]
      }
      msg = SES.build_message("html", "text", "subject")

      expected = %{
        "Action" => "SendEmail", "ConfigurationSetName" => "test",
        "Destination.ToAddresses.member.1" => "success@simulator.amazonses.com",
        "Destination.ToAddresses.member.2" => "bounce@simulator.amazonses.com",
        "Destination.CcAddresses.member.1" => "success@simulator.amazonses.com",
        "Destination.BccAddresses.member.1" => "success@simulator.amazonses.com",
        "Message.Body.Html.Data" => "html", "Message.Body.Html.Charset" => "UTF-8",
        "Message.Body.Text.Data" => "text", "Message.Body.Text.Charset" => "UTF-8",
        "Message.Subject.Data" => "subject", "Message.Subject.Charset" => "UTF-8",
        "ReplyToAddresses.member.1" => "user@example.com", "ReplyToAddresses.member.2" => "user1@example.com",
        "ReturnPath" => "feedback@example.com",
        "ReturnPathArn" => "arn:aws:ses:us-east-1:123456789012:identity/example.com",
        "Source" => "user@example.com",
        "SourceArn" => "east-1:123456789012:identity/example.com",
        "Tags.member.1.Name" => "tag1", "Tags.member.1.Value" => "tag1value1",
        "Tags.member.2.Name" => "tag2", "Tags.member.2.Value" => "tag2value1"
      }

      assert expected == SES.send_email(
        dst, msg, "user@example.com", configuration_set_name: "test", return_path: "feedback@example.com",
        return_path_arn: "arn:aws:ses:us-east-1:123456789012:identity/example.com",
        source_arn: "east-1:123456789012:identity/example.com",
        reply_to: ["user@example.com", "user1@example.com"],
        tags:  [%{name: "tag1", value: "tag1value1"}, %{name: "tag2", value: "tag2value1"}]
      ).params
    end
  end

  describe "#send_templated_email" do
    test "with required params only" do
      dst =  %{to:  ["success@simulator.amazonses.com"]}
      src = "user@example.com"
      template_data = %{data1: "data1", data2: "data2"}

      expected = %{
        "Action" => "SendTemplatedEmail", "Destination.ToAddresses.member.1" => "success@simulator.amazonses.com",
        "Template" => "my_template", "Source" => "user@example.com", "TemplateData" => Poison.encode!(template_data)
      }

      assert expected == SES.send_templated_email(dst, src, "my_template", template_data).params
    end

    test "with all optional params" do
      dst =  %{
        bcc: ["success@simulator.amazonses.com"],
        cc:  ["success@simulator.amazonses.com"],
        to:  ["success@simulator.amazonses.com", "bounce@simulator.amazonses.com"]
      }

      src = "user@example.com"
      template_data = %{data1: "data1", data2: "data2"}

      expected = %{
        "Action" => "SendTemplatedEmail", "ConfigurationSetName" => "test",
        "Destination.ToAddresses.member.1" => "success@simulator.amazonses.com",
        "Destination.ToAddresses.member.2" => "bounce@simulator.amazonses.com",
        "Destination.CcAddresses.member.1" => "success@simulator.amazonses.com",
        "Destination.BccAddresses.member.1" => "success@simulator.amazonses.com",
        "ReplyToAddresses.member.1" => "user@example.com", "ReplyToAddresses.member.2" => "user1@example.com",
        "ReturnPath" => "feedback@example.com",
        "ReturnPathArn" => "arn:aws:ses:us-east-1:123456789012:identity/example.com",
        "Source" => "user@example.com",
        "SourceArn" => "east-1:123456789012:identity/example.com",
        "Tags.member.1.Name" => "tag1", "Tags.member.1.Value" => "tag1value1",
        "Tags.member.2.Name" => "tag2", "Tags.member.2.Value" => "tag2value1",
        "Template" => "my_template", "TemplateData" => Poison.encode!(template_data)
      }

      assert expected == SES.send_templated_email(
        dst, src, "my_template", template_data, configuration_set_name: "test", return_path: "feedback@example.com",
        return_path_arn: "arn:aws:ses:us-east-1:123456789012:identity/example.com",
        source_arn: "east-1:123456789012:identity/example.com",
        reply_to: ["user@example.com", "user1@example.com"],
        tags:  [%{name: "tag1", value: "tag1value1"}, %{name: "tag2", value: "tag2value1"}]
      ).params
    end
  end

  describe "#send_bulk_templated_email" do
    test "with required params only" do
      template = "my_template"
      source = "user@example.com"

      replacement_template_data1 = %{data1: "value1"}
      replacement_template_data2 = %{data1: "value2"}

      destinations = [
        %{destination: %{to: ["email1@email.com", "email2@email.com"]}, replacement_template_data: replacement_template_data1},
        %{
          destination: %{to: ["email3@email.com"], cc: ["email4@email.com", "email5@email.com"], bcc: ["email6@email.com", "email7@email.com"]},
          replacement_template_data: replacement_template_data2
        },
        %{destination: %{to: ["email8@email.com"]}}
      ]

      expected = %{
        "Action" => "SendBulkTemplatedEmail",
        "Template" => "my_template",
        "Source" => "user@example.com",
        "Destinations.member.1.Destination.ToAddresses.member.1" => "email1@email.com",
        "Destinations.member.1.Destination.ToAddresses.member.2" => "email2@email.com",
        "Destinations.member.1.ReplacementTemplateData" => Poison.encode!(replacement_template_data1),
        "Destinations.member.2.Destination.ToAddresses.member.1" => "email3@email.com",
        "Destinations.member.2.Destination.CcAddresses.member.1" => "email4@email.com",
        "Destinations.member.2.Destination.CcAddresses.member.2" => "email5@email.com",
        "Destinations.member.2.Destination.BccAddresses.member.1" => "email6@email.com",
        "Destinations.member.2.Destination.BccAddresses.member.2" => "email7@email.com",
        "Destinations.member.2.ReplacementTemplateData" => Poison.encode!(replacement_template_data2),
        "Destinations.member.3.Destination.ToAddresses.member.1" => "email8@email.com",
        "DefaultTemplateData" => "{}"
      }

      assert expected == SES.send_bulk_templated_email(template, source, destinations).params
    end

    test "with all optional params" do
      template = "my_template"
      source = "user@example.com"

      replacement_template_data1 = %{data1: "value1"}
      replacement_template_data2 = %{data1: "value2"}
      default_template_data = %{data1: "DefaultValue"}

      destinations = [
        %{destination: %{to: ["email1@email.com", "email2@email.com"]}, replacement_template_data: replacement_template_data1},
        %{
          destination: %{to: ["email3@email.com"], cc: ["email4@email.com", "email5@email.com"], bcc: ["email6@email.com", "email7@email.com"]},
          replacement_template_data: replacement_template_data2
        },
        %{destination: %{to: ["email8@email.com"]}}
      ]

      expected = %{
        "Action" => "SendBulkTemplatedEmail",
        "ConfigurationSetName" => "test",
        "Template" => "my_template",
        "Source" => "user@example.com",
        "Destinations.member.1.Destination.ToAddresses.member.1" => "email1@email.com",
        "Destinations.member.1.Destination.ToAddresses.member.2" => "email2@email.com",
        "Destinations.member.1.ReplacementTemplateData" => Poison.encode!(replacement_template_data1),
        "Destinations.member.2.Destination.ToAddresses.member.1" => "email3@email.com",
        "Destinations.member.2.Destination.CcAddresses.member.1" => "email4@email.com",
        "Destinations.member.2.Destination.CcAddresses.member.2" => "email5@email.com",
        "Destinations.member.2.Destination.BccAddresses.member.1" => "email6@email.com",
        "Destinations.member.2.Destination.BccAddresses.member.2" => "email7@email.com",
        "Destinations.member.2.ReplacementTemplateData" => Poison.encode!(replacement_template_data2),
        "Destinations.member.3.Destination.ToAddresses.member.1" => "email8@email.com",
        "DefaultTemplateData" => Poison.encode!(default_template_data),
        "ReturnPath" => "feedback@example.com",
        "ReturnPathArn" => "arn:aws:ses:us-east-1:123456789012:identity/example.com",
        "SourceArn" => "east-1:123456789012:identity/example.com",
        "DefaultTags.member.1.Name" => "tag1",
        "DefaultTags.member.1.Value" => "tag1value1",
        "DefaultTags.member.2.Name" => "tag2",
        "DefaultTags.member.2.Value" => "tag2value1",
      }

      assert expected ==
               SES.send_bulk_templated_email(
                 template,
                 source,
                 destinations,
                 default_template_data: default_template_data,
                 configuration_set_name: "test",
                 return_path: "feedback@example.com",
                 return_path_arn: "arn:aws:ses:us-east-1:123456789012:identity/example.com",
                 source_arn: "east-1:123456789012:identity/example.com",
                 reply_to: ["user@example.com", "user1@example.com"],
                 default_tags: [%{name: "tag1", value: "tag1value1"}, %{name: "tag2", value: "tag2value1"}]
               ).params
    end
  end

  test "#delete_identity", ctx do
    expected = %{"Action" => "DeleteIdentity", "Identity" => ctx.email}
    assert expected == SES.delete_identity(ctx.email).params
  end

  describe "#set_identity_notification_topic" do
    test "accepts correct notification types", ctx do
      Enum.each([:bounce, :complaint, :delivery], fn type ->
        notification_type = Atom.to_string(type) |> String.capitalize()
        expected = %{
          "Action" => "SetIdentityNotificationTopic", "Identity" => ctx.email, "NotificationType" => notification_type
        }

        assert expected == SES.set_identity_notification_topic(ctx.email, type).params
      end)
    end

    test "optional params", ctx do
      sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:my_corporate_topic:02034b43-fefa-4e07-a5eb-3be56f8c54ce"
      expected = %{
        "Action" => "SetIdentityNotificationTopic", "Identity" => ctx.email, "NotificationType" => "Bounce",
        "SnsTopic" => sns_topic_arn
      }

      assert expected == SES.set_identity_notification_topic(ctx.email, :bounce, sns_topic: sns_topic_arn).params
    end
  end

  test "#set_identity_feedback_forwarding_enabled", ctx do
    enabled = true
    expected = %{
      "Action" => "SetIdentityFeedbackForwardingEnabled", "ForwardingEnabled" => enabled, "Identity" => ctx.email
    }

    assert expected == SES.set_identity_feedback_forwarding_enabled(enabled, ctx.email).params
  end

  test "#set_identity_headers_in_notifications_enabled", ctx do
    enabled = true
    expected = %{
      "Action" => "SetIdentityHeadersInNotificationsEnabled", "Identity" => ctx.email, "Enabled" => enabled,
      "NotificationType" =>"Delivery"
    }

    assert expected == SES.set_identity_headers_in_notifications_enabled(ctx.email, :delivery, enabled).params
  end


  describe "#create_template" do
    test "with required params only" do
      templateName = "MyTemplate"
      subject = "Greetings, {{name}}!"
      html = "<h1>Hello {{name}},</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
      text = "Dear {{name}},\r\nYour favorite animal is {{favoriteanimal}}."

      expected = %{
        "Action" => "CreateTemplate",
        "Template.TemplateName" => templateName,
        "Template.SubjectPart" => subject,
        "Template.HtmlPart" => html,
        "Template.TextPart" => text
      }

      assert expected == SES.create_template(templateName, subject, html, text).params
    end

    test "without text part" do
      templateName = "MyTemplate"
      subject = "Greetings, {{name}}!"
      html = "<h1>Hello {{name}},</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
      text = "Dear {{name}},\r\nYour favorite animal is {{favoriteanimal}}."

      expected = %{
        "Action" => "CreateTemplate",
        "Template.TemplateName" => templateName,
        "Template.SubjectPart" => subject,
        "Template.HtmlPart" => html
      }

      assert expected == SES.create_template(templateName, subject, html, nil).params
    end

    test "with all optional params" do
      templateName = "MyTemplate"
      subject = "Greetings, {{name}}!"
      html = "<h1>Hello {{name}},</h1><p>Your favorite animal is {{favoriteanimal}}.</p>"
      text = "Dear {{name}},\r\nYour favorite animal is {{favoriteanimal}}."

      expected = %{
        "Action" => "CreateTemplate",
        "Template.TemplateName" => templateName,
        "Template.SubjectPart" => subject,
        "Template.HtmlPart" => html,
        "Template.TextPart" => text,
        "ConfigurationSetName" => "test"
      }

      assert expected == SES.create_template(templateName, subject, html, text, configuration_set_name: "test").params
    end
  end

  test "#delete_template" do
    templateName = "MyTemplate"

    expected = %{
      "Action" => "DeleteTemplate",
      "TemplateName" => templateName
    }

    assert expected == SES.delete_template(templateName).params
  end
end
