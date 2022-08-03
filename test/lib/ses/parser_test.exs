defmodule ExAws.SES.ParserTest do
  use ExUnit.Case, async: true

  alias ExAws.SES.Parsers

  defp to_success(doc) do
    {:ok, %{body: doc}}
  end

  defp to_error(doc) do
    {:error, {:http_error, 403, %{body: doc}}}
  end

  test "#parse a verify_email_identity response" do
    rsp =
      """
        <VerifyEmailIdentityResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
        <VerifyEmailIdentityResult/>
          <ResponseMetadata>
            <RequestId>d8eb8250-be9b-11e6-b7f7-d570946af758</RequestId>
          </ResponseMetadata>
        </VerifyEmailIdentityResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :verify_email_identity)
    assert parsed_doc == %{request_id: "d8eb8250-be9b-11e6-b7f7-d570946af758"}
  end

  test "#parse a verify_domain_identity response" do
    rsp =
      """
        <VerifyDomainIdentityResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <VerifyDomainIdentityResult>
            <VerificationToken>u4GmlJ3cPJfxxZbLSPMkLOPjQvJW1HPvA6Pmi21CPIE=</VerificationToken>
          </VerifyDomainIdentityResult>
          <ResponseMetadata>
            <RequestId>d8eb8250-be9b-11e6-b7f7-d570946af758</RequestId>
          </ResponseMetadata>
        </VerifyDomainIdentityResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :verify_domain_identity)
    assert parsed_doc == %{request_id: "d8eb8250-be9b-11e6-b7f7-d570946af758", verification_token: "u4GmlJ3cPJfxxZbLSPMkLOPjQvJW1HPvA6Pmi21CPIE="}
  end

  test "#parse a verify_domain_dkim response" do
    rsp =
      """
        <VerifyDomainDkimResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <VerifyDomainDkimResult>
            <DkimTokens>
              <member>5livxhounddpfqprdog22m4c337ake5o</member>
              <member>tbnwx5g3l0zmstwf2c258r36pvpnksbt</member>
              <member>bbtl43drumsloilm2zfjlhj3c7v12a5d</member>
            </DkimTokens>
          </VerifyDomainDkimResult>
          <ResponseMetadata>
            <RequestId>d8eb8250-be9b-11e6-b7f7-d570946af758</RequestId>
          </ResponseMetadata>
        </VerifyDomainDkimResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :verify_domain_dkim)
    assert parsed_doc == %{request_id: "d8eb8250-be9b-11e6-b7f7-d570946af758", dkim_tokens: %{members: ["5livxhounddpfqprdog22m4c337ake5o", "tbnwx5g3l0zmstwf2c258r36pvpnksbt", "bbtl43drumsloilm2zfjlhj3c7v12a5d"]}}
  end


  test "#parse identity_verification_attributes" do
    rsp =
      """
        <GetIdentityVerificationAttributesResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <GetIdentityVerificationAttributesResult>
            <VerificationAttributes>
              <entry>
                <key>example.com</key>
                <value>
                  <VerificationToken>pwCRTZ8zHIJu+vePnXEa4DJmDyGhjSS8V3TkzzL2jI8=</VerificationToken>
                  <VerificationStatus>Pending</VerificationStatus>
                </value>
              </entry>
              <entry>
                <key>user@example.com</key>
                <value>
                  <VerificationStatus>Pending</VerificationStatus>
                </value>
              </entry>
            </VerificationAttributes>
          </GetIdentityVerificationAttributesResult>
          <ResponseMetadata>
            <RequestId>f5e3ef21-bec1-11e6-b618-27019a58dab9</RequestId>
          </ResponseMetadata>
        </GetIdentityVerificationAttributesResponse>
      """
      |> to_success

    verification_attributes = %{
      "example.com" => %{
        verification_token: "pwCRTZ8zHIJu+vePnXEa4DJmDyGhjSS8V3TkzzL2jI8=",
        verification_status: "Pending"
      },
      "user@example.com" => %{
        verification_status: "Pending"
      }
    }

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :get_identity_verification_attributes)
    assert parsed_doc[:verification_attributes] == verification_attributes
  end

  test "#parse configuration_sets" do
    rsp =
      """
        <ListConfigurationSetsResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
          <ListConfigurationSetsResult>
            <ConfigurationSets>
              <member>
                <Name>test</Name>
              </member>
            </ConfigurationSets>
            <NextToken>QUFBQUF</NextToken>
          </ListConfigurationSetsResult>
          <ResponseMetadata>
            <RequestId>c177d6ce-c1b0-11e6-9770-29713cf492ad</RequestId>
          </ResponseMetadata>
        </ListConfigurationSetsResponse>
      """
      |> to_success

    configuration_sets = %{
      members: ["test"],
      next_token: "QUFBQUF"
    }

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :list_configuration_sets)
    assert parsed_doc[:configuration_sets] == configuration_sets
  end

  test "#parse send_email" do
    rsp =
      """
      <SendEmailResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
        <SendEmailResult>
          <MessageId>0100015914b22075-7a4e3573-ca72-41ce-8eda-388f81232ad9-000000</MessageId>
        </SendEmailResult>
        <ResponseMetadata>
          <RequestId>8194094b-c58a-11e6-b49d-838795cc7d3f</RequestId>
        </ResponseMetadata>
      </SendEmailResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :send_email)

    assert parsed_doc == %{
             request_id: "8194094b-c58a-11e6-b49d-838795cc7d3f",
             message_id: "0100015914b22075-7a4e3573-ca72-41ce-8eda-388f81232ad9-000000"
           }
  end

  test "#parse send_templated_email" do
    rsp =
      """
      <SendTemplatedEmailResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
        <SendTemplatedEmailResult>
          <MessageId>0100015914b22075-7a4e3573-ca72-41ce-8eda-388f81232ad9-000000</MessageId>
        </SendTemplatedEmailResult>
        <ResponseMetadata>
          <RequestId>8194094b-c58a-11e6-b49d-838795cc7d3f</RequestId>
        </ResponseMetadata>
      </SendTemplatedEmailResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :send_templated_email)

    assert parsed_doc == %{
             request_id: "8194094b-c58a-11e6-b49d-838795cc7d3f",
             message_id: "0100015914b22075-7a4e3573-ca72-41ce-8eda-388f81232ad9-000000"
           }
  end

  test "#parse send_bulk_templated_email" do
    rsp =
      """
      <SendBulkTemplatedEmailResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
        <SendBulkTemplatedEmailResult>
          <Status>
            <member>
              <MessageId>110000663377dd66-44ffaaaa-11bb-44dd-aa77-998899883388-000000</MessageId>
              <Status>Success</Status>
            </member>
            <member>
              <MessageId>110000663377dd66-778888dd-cc99-44aa-aa99-bbdd99ddff88-000000</MessageId>
              <Status>Success</Status>
            </member>
          </Status>
        </SendBulkTemplatedEmailResult>
        <ResponseMetadata>
          <RequestId>22ff88dd-cc11-11ee-99bb-5599ee1144dd</RequestId>
        </ResponseMetadata>
      </SendBulkTemplatedEmailResponse>"
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :send_bulk_templated_email)

    assert parsed_doc == %{
             request_id: "22ff88dd-cc11-11ee-99bb-5599ee1144dd",
             messages: [
               %{message_id: "110000663377dd66-44ffaaaa-11bb-44dd-aa77-998899883388-000000", status: "Success"},
               %{message_id: "110000663377dd66-778888dd-cc99-44aa-aa99-bbdd99ddff88-000000", status: "Success"}
             ]
           }
  end

  test "#parse send_raw_email" do
    rsp =
      """
      <SendRawEmailResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
        <SendRawEmailResult>
          <MessageId>0101018264278cea-406a0406-5f46-412b-8f32-05ef31a62aa0-000000</MessageId>
        </SendRawEmailResult>
        <ResponseMetadata>
          <RequestId>3c2ddfd4-ff21-4a3d-af5f-97ec74811e22</RequestId>
        </ResponseMetadata>
      </SendRawEmailResponse>
      """
      |> to_success()

      {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :send_raw_email)
      assert parsed_doc == %{
        request_id: "3c2ddfd4-ff21-4a3d-af5f-97ec74811e22",
        message_id: "0101018264278cea-406a0406-5f46-412b-8f32-05ef31a62aa0-000000"
      }
  end

  test "#parse a delete_identity response" do
    rsp =
      """
        <DeleteIdentityResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <DeleteIdentityResult/>
          <ResponseMetadata>
            <RequestId>88c79dfb-1472-11e7-94c4-4d1ecf50b91f</RequestId>
          </ResponseMetadata>
        </DeleteIdentityResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :delete_identity)
    assert parsed_doc == %{request_id: "88c79dfb-1472-11e7-94c4-4d1ecf50b91f"}
  end

  test "#parse a set_identity_notification_topic response" do
    rsp =
      """
        <SetIdentityNotificationTopicResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <SetIdentityNotificationTopicResult/>
          <ResponseMetadata>
            <RequestId>3d3f811a-1484-11e7-b9b1-db4762b6c4db</RequestId>
          </ResponseMetadata>
        </SetIdentityNotificationTopicResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :set_identity_notification_topic)
    assert parsed_doc == %{request_id: "3d3f811a-1484-11e7-b9b1-db4762b6c4db"}
  end

  test "#parse a set_identity_feedback_forwarding_enabled response" do
    rsp =
      """
        <SetIdentityFeedbackForwardingEnabledResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <SetIdentityFeedbackForwardingEnabledResult/>
          <ResponseMetadata>
            <RequestId>f1cc8133-149a-11e7-91a5-ed1259cbd185</RequestId>
          </ResponseMetadata>
        </SetIdentityFeedbackForwardingEnabledResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :set_identity_feedback_forwarding_enabled)
    assert parsed_doc == %{request_id: "f1cc8133-149a-11e7-91a5-ed1259cbd185"}
  end

  test "#parse a set_identity_headers_in_notifications_enabled response" do
    rsp =
      """
        <SetIdentityHeadersInNotificationsEnabledResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <SetIdentityHeadersInNotificationsEnabledResult/>
          <ResponseMetadata>
            <RequestId>01b49b78-30ca-11e7-948a-399bafb173a2</RequestId>
          </ResponseMetadata>
        </SetIdentityHeadersInNotificationsEnabledResponse>"
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :set_identity_headers_in_notifications_enabled)
    assert parsed_doc == %{request_id: "01b49b78-30ca-11e7-948a-399bafb173a2"}
  end

  test "#parse create_template" do
    rsp =
      """
      <CreateTemplateResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
        <CreateTemplateResult/>
        <ResponseMetadata>
          <RequestId>9876defg-c666-111e-88aa-ee8833eeffaa</RequestId>
        </ResponseMetadata>
      </CreateTemplateResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :create_template)
    assert parsed_doc == %{request_id: "9876defg-c666-111e-88aa-ee8833eeffaa"}
  end

  test "#parse delete_template" do
    rsp =
      """
      <DeleteTemplateResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
        <DeleteTemplateResult/>
          <ResponseMetadata>
            <RequestId>12345abcd-c666-111e-88aa-cc8899bb1177</RequestId>
          </ResponseMetadata>
      </DeleteTemplateResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :delete_template)
    assert parsed_doc == %{request_id: "12345abcd-c666-111e-88aa-cc8899bb1177"}
  end

  test "#parse list_identities" do
    rsp =
      """
        <ListIdentitiesResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
          <ListIdentitiesResult>
            <Identities>
              <member>user@example.com</member>
              <member>user2@example.com</member>
            </Identities>
          </ListIdentitiesResult>
          <ResponseMetadata>
            <RequestId>12345abcd-c666-111e-88aa-cc8899bb1177</RequestId>
          </ResponseMetadata>
        </ListIdentitiesResponse>
      """
      |> to_success

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :list_identities)

    assert parsed_doc == %{
             request_id: "12345abcd-c666-111e-88aa-cc8899bb1177",
             custom_verification_email_templates: %{
               members: ["user@example.com", "user2@example.com"],
               next_token: ""
             },
             identities: %{
               members: ["user@example.com", "user2@example.com"],
               next_token: ""
             }
           }
  end

  test "#parse list_custom_verification_email_templates" do
    rsp =
      """
      <ListCustomVerificationEmailTemplatesResponse xmlns=\"http://ses.amazonaws.com/doc/2010-12-01/\">
        <ListCustomVerificationEmailTemplatesResult>
          <CustomVerificationEmailTemplates>
            <member>
              <TemplateSubject>Subject</TemplateSubject>
              <FailureRedirectionURL>https://example.com/failure</FailureRedirectionURL>
              <SuccessRedirectionURL>https://example.com/success</SuccessRedirectionURL>
              <FromEmailAddress>user@example.com</FromEmailAddress>
              <TemplateName>Template Name</TemplateName>
            </member>
          </CustomVerificationEmailTemplates>
        </ListCustomVerificationEmailTemplatesResult>
        <ResponseMetadata>
          <RequestId>12345abcd-c666-111e-88aa-cc8899bb1177</RequestId>
        </ResponseMetadata>
      </ListCustomVerificationEmailTemplatesResponse>
      """
      |> to_success()

    {:ok, %{body: parsed_doc}} = Parsers.parse(rsp, :list_custom_verification_email_templates)

    assert parsed_doc == %{
             request_id: "12345abcd-c666-111e-88aa-cc8899bb1177",
             custom_verification_email_templates: %{
               members: [
                 %{
                   template_name: "Template Name",
                   template_subject: "Subject",
                   failure_redirection_url: "https://example.com/failure",
                   success_redirection_url: "https://example.com/success",
                   from_email_address: "user@example.com"
                 }
               ],
               next_token: ""
             }
           }
  end

  test "#parse error" do
    rsp =
      """
        <ErrorResponse xmlns="http://ses.amazonaws.com/doc/2010-12-01/">
          <Error>
            <Type>Sender</Type>
            <Code>MalformedInput</Code>
            <Message>Top level element may not be treated as a list</Message>
          </Error>
          <RequestId>3ac0a9e8-bebd-11e6-9ec4-e5c47e708fa8</RequestId>
        </ErrorResponse>
      """
      |> to_error

    {:error, {:http_error, 403, err}} = Parsers.parse(rsp, :get_identity_verification_attributes)

    assert "Sender" == err[:type]
    assert "MalformedInput" == err[:code]
    assert "Top level element may not be treated as a list" == err[:message]
    assert "3ac0a9e8-bebd-11e6-9ec4-e5c47e708fa8" == err[:request_id]
  end
end
