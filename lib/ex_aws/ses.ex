defmodule ExAws.SES do
  import ExAws.Utils, only: [camelize_key: 1, camelize_keys: 1]

  @moduledoc """
  Operations on AWS SES.

  See https://docs.aws.amazon.com/ses/latest/APIReference/Welcome.html
  """

  @notification_types [:bounce, :complaint, :delivery]
  @service :ses
  @v2_path "/v2/email"

  @doc """
  Verifies an email address.
  """
  @spec verify_email_identity(email :: binary) :: ExAws.Operation.Query.t()
  def verify_email_identity(email) do
    request(:verify_email_identity, %{"EmailAddress" => email})
  end

  @doc """
  Verifies a domain.
  """
  @spec verify_domain_identity(domain :: binary) :: ExAws.Operation.Query.t()
  def verify_domain_identity(domain) do
    request(:verify_domain_identity, %{"Domain" => domain})
  end

  @doc """
  Verifies a domain with DKIM.
  """
  @spec verify_domain_dkim(domain :: binary) :: ExAws.Operation.Query.t()
  def verify_domain_dkim(domain) do
    request(:verify_domain_dkim, %{"Domain" => domain})
  end

  @type list_identities_opt ::
          {:max_items, pos_integer}
          | {:next_token, String.t()}
          | {:identity_type, String.t()}

  @type tag :: %{Key: String.t(), Value: String.t()}
  @type list_topic :: %{String.t() => String.t()}
  @type suppression_reason :: :BOUNCE | :COMPLAINT

  @doc "List identities associated with the AWS account"
  @spec list_identities(opts :: [] | [list_identities_opt]) :: ExAws.Operation.Query.t()
  @deprecated "The :custom_verification_templates key will be deprecated in version 3.x.x, please use :identities instead"
  def list_identities(opts \\ []) do
    params = build_opts(opts, [:max_items, :next_token, :identity_type])
    request(:list_identities, params)
  end

  @doc """
  Fetch identities verification status and token (for domains).
  """
  @spec get_identity_verification_attributes([binary]) :: ExAws.Operation.Query.t()
  def get_identity_verification_attributes(identities) when is_list(identities) do
    params = format_member_attribute({:identities, identities})
    request(:get_identity_verification_attributes, params)
  end

  @type list_configuration_sets_opt ::
          {:max_items, pos_integer}
          | {:next_token, String.t()}

  @doc """
  Fetch configuration sets associated with AWS account.
  """
  @spec list_configuration_sets() :: ExAws.Operation.Query.t()
  @spec list_configuration_sets(opts :: [] | [list_configuration_sets_opt]) :: ExAws.Operation.Query.t()
  def list_configuration_sets(opts \\ []) do
    params = build_opts(opts, [:max_items, :next_token])
    request(:list_configuration_sets, params)
  end

  ## Contact lists
  ######################

  @doc """
  Create a contact list via the SES V2 API,
  see (https://docs.aws.amazon.com/ses/latest/APIReference-V2/).

  ## Examples

      ExAws.SES.create_contact_list(
        "Test list",
        "Test description",
        tags: [%{"Key" => "environment", "Value" => "test"}],
        topics: [
          %{
            "TopicName": "test_topic"
            "DisplayName": "Test topic",
            "Description": "Test discription",
            "DefaultSubscriptionStatus": "OPT_IN",
          }
       ]
      )

  """
  @type create_contact_list_opt ::
          {:description, String.t()}
          | {:tags, [tag]}
          | {:topics, [%{(String.t() | atom) => String.t()}]}
  @spec create_contact_list(String.t(), opts :: [create_contact_list_opt]) ::
          ExAws.Operation.JSON.t()
  def create_contact_list(list_name, opts \\ []) do
    data =
      prune_map(%{
        "ContactListName" => list_name,
        "Description" => opts[:description],
        "Tags" => opts[:tags],
        "Topics" => opts[:topics]
      })

    request_v2(:post, "contact-lists")
    |> Map.put(:data, data)
  end

  @doc """
  Update a contact list. Only accepts description and topic updates.

  ## Examples

      ExAws.SES.update_contact_list("test_list", description: "New description")

  """
  @type topic :: %{
          required(:DefaultSubscriptionStatus) => String.t(),
          optional(:Description) => String.t(),
          required(:DisplayName) => String.t(),
          required(:TopicName) => String.t()
        }
  @type update_contact_list_opt ::
          {:description, String.t()}
          | {:topics, [topic]}
  @spec update_contact_list(String.t(), opts :: [update_contact_list_opt]) :: ExAws.Operation.JSON.t()
  def update_contact_list(list_name, opts \\ []) do
    data =
      prune_map(%{
        "ContactListName" => list_name,
        "Description" => opts[:description],
        "Topics" => opts[:topics]
      })

    request_v2(:put, "contact-lists/#{list_name}")
    |> Map.put(:data, data)
  end

  @doc """
  List contact lists.

  The API accepts pagination parameters, but they're redundant as AWS limits
  usage to a single list per account.
  """
  @spec list_contact_lists() :: ExAws.Operation.JSON.t()
  def list_contact_lists() do
    request_v2(:get, "contact-lists")
  end

  @doc """
  Show contact list.
  """
  @spec get_contact_list(String.t()) :: ExAws.Operation.JSON.t()
  def get_contact_list(list_name) do
    request_v2(:get, "contact-lists/#{list_name}")
  end

  @doc """
  Delete contact list.
  """
  @spec delete_contact_list(String.t()) :: ExAws.Operation.JSON.t()
  def delete_contact_list(list_name) do
    request_v2(:delete, "contact-lists/#{list_name}")
  end

  ## Contacts
  ######################

  @doc """
  Create a new contact in a contact list.

  Options:

  * `:attributes` - arbitrary string to be assigned to AWS SES Contact AttributesData
  * `:topic_preferences` - list of maps for subscriptions to topics.
    SubscriptionStatus should be one of "OPT_IN" or "OPT_OUT"
  * `:unsubscribe_all` - causes contact to be unsubscribed from all topics
  """
  @type topic_preference :: %{
          TopicName: String.t(),
          SubscriptionStatus: String.t()
        }
  @type contact_opt ::
          {:attributes, String.t()}
          | {:topic_preferences, [topic_preference]}
          | {:unsubscribe_all, Boolean.t()}
  @spec create_contact(String.t(), email_address, [contact_opt]) :: ExAws.Operation.JSON.t()
  def create_contact(list_name, email, opts \\ []) do
    data =
      prune_map(%{
        "EmailAddress" => email,
        "TopicPreferences" => opts[:topic_preferences],
        "AttributesData" => opts[:attributes],
        "UnsubscribeAll" => opts[:unsubscribe_all]
      })

    request_v2(:post, "contact-lists/#{list_name}/contacts")
    |> Map.put(:data, data)
  end

  @doc """
  Update a contact in a contact list.
  """
  @spec update_contact(String.t(), email_address, [contact_opt]) :: ExAws.Operation.JSON.t()
  def update_contact(list_name, email, opts \\ []) do
    data =
      prune_map(%{
        "TopicPreferences" => opts[:topic_preferences],
        "AttributesData" => opts[:attributes],
        "UnsubscribeAll" => opts[:unsubscribe_all]
      })

    uri_encoded_email = ExAws.Request.Url.uri_encode(email)

    request_v2(:put, "contact-lists/#{list_name}/contacts/#{uri_encoded_email}")
    |> Map.put(:data, data)
  end

  @doc """
  Show contacts in contact list.
  """
  @spec list_contacts(String.t()) :: ExAws.Operation.JSON.t()
  def list_contacts(list_name) do
    request_v2(:get, "contact-lists/#{list_name}/contacts")
  end

  @doc """
  Show a contact in a contact list.
  """
  @spec get_contact(String.t(), email_address) :: ExAws.Operation.JSON.t()
  def get_contact(list_name, email) do
    uri_encoded_email = ExAws.Request.Url.uri_encode(email)
    request_v2(:get, "contact-lists/#{list_name}/contacts/#{uri_encoded_email}")
  end

  @doc """
  Delete a contact in a contact list.
  """
  @spec delete_contact(String.t(), email_address) :: ExAws.Operation.JSON.t()
  def delete_contact(list_name, email) do
    uri_encoded_email = ExAws.Request.Url.uri_encode(email)
    request_v2(:delete, "contact-lists/#{list_name}/contacts/#{uri_encoded_email}")
  end

  @doc """
  Create a bulk import job to import contacts from S3.

  Params:

  * `:import_data_source`
  * `:import_destination` - requires either a `ContactListDestination` or
    `SuppressionListDestination` map.
  """
  @type import_data_source :: %{DataFormat: String.t(), S3Url: String.t()}
  @type contact_list_destination :: %{
          ContactListImportAction: String.t(),
          ContactListName: String.t()
        }
  @type suppression_list_destination :: %{SuppressionListImportAction: String.t()}
  @type import_destination :: %{
          optional(:ContactListDestination) => contact_list_destination(),
          optional(:SuppressionListDestination) => suppression_list_destination()
        }
  @spec create_import_job(import_data_source(), import_destination()) :: ExAws.Operation.JSON.t()
  def create_import_job(data_source, destination) do
    data = %{
      ImportDataSource: data_source,
      ImportDestination: destination
    }

    request_v2(:post, "import-jobs")
    |> Map.put(:data, data)
  end

  ## Suppression Lists
  ######################
  @doc """
  Add an email address to list of suppressed destinations. A suppression reason
  is mandatory (see `t:suppression_reason()`).
  """
  @spec put_suppressed_destination(String.t(), SuppressionReason.t()) :: ExAws.Operation.JSON.t()
  def put_suppressed_destination(email_address, suppression_reason) do
    request_v2(:put, "suppression/addresses")
    |> Map.put(:data, %{
      EmailAddress: email_address,
      Reason: suppression_reason
    })
  end

  @doc """
  Delete an email address from list of suppressed destinations.
  """
  @spec delete_suppressed_destination(String.t()) :: ExAws.Operation.JSON.t()
  def delete_suppressed_destination(email_address) do
    uri_encoded_email_address = ExAws.Request.Url.uri_encode(email_address)

    request_v2(:delete, "suppression/addresses/#{uri_encoded_email_address}")
  end

  ## Templates
  ######################

  @doc "Get email template"
  @spec get_template(String.t()) :: ExAws.Operation.Query.t()
  def get_template(template_name) do
    request(:get_template, %{"TemplateName" => template_name})
  end

  @doc """
  Get an email templates via V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_GetEmailTemplate.html
  """
  @spec get_email_template(String.t()) :: ExAws.Operation.JSON.t()
  def get_email_template(template_name) do
    request_v2(:get, "templates/#{template_name}")
  end

  @type list_templates_opt ::
          {:max_items, pos_integer}
          | {:next_token, String.t()}

  @doc """
  List email templates.
  """
  @spec list_templates(opts :: [] | [list_templates_opt]) :: ExAws.Operation.Query.t()
  def list_templates(opts \\ []) do
    params = build_opts(opts, [:max_items, :next_token])
    request(:list_templates, params)
  end

  @doc """
  List email templates via V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_ListEmailTemplate.html
  """
  @type list_templates_opt_v2 ::
          {:page_size, pos_integer}
          | {:next_token, String.t()}
  @spec list_email_templates(opts :: [] | [list_templates_opt_v2]) :: ExAws.Operation.JSON.t()
  def list_email_templates(opts \\ []) do
    params = build_opts(opts, [:page_size, :next_token])
    request_v2(:get, "templates?#{URI.encode_query(params)}")
  end

  @doc """
  Creates an email template.
  """
  @type create_template_opt :: {:configuration_set_name, String.t()}
  @spec create_template(String.t(), String.t(), String.t(), String.t(), opts :: [create_template_opt]) ::
          ExAws.Operation.Query.t()
  def create_template(template_name, subject, html, text, opts \\ []) do
    template =
      %{
        "TemplateName" => template_name,
        "SubjectPart" => subject
      }
      |> put_if_not_nil("HtmlPart", html)
      |> put_if_not_nil("TextPart", text)
      |> flatten_attrs("Template")

    params =
      opts
      |> build_opts([:configuration_set_name])
      |> Map.merge(template)

    request(:create_template, params)
  end

  @doc """
  Create an email template via V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_CreateEmailTemplate.html
  """
  @spec create_email_template(String.t(), String.t(), String.t(), String.t()) :: ExAws.Operation.JSON.t()
  def create_email_template(template_name, subject, html, text) do
    template_content =
      %{
        "Subject" => subject
      }
      |> put_if_not_nil("Html", html)
      |> put_if_not_nil("Text", text)

    params =
      %{
        "TemplateName" => template_name,
        "TemplateContent" => template_content
      }

    request_v2(:post, "templates")
    |> Map.put(:data, params)
  end

  @doc """
  Updates an email template.
  """
  @type update_template_opt :: {:configuration_set_name, String.t()}
  @spec update_template(String.t(), String.t(), String.t(), String.t(), opts :: [update_template_opt]) ::
          ExAws.Operation.Query.t()
  def update_template(template_name, subject, html, text, opts \\ []) do
    template =
      %{
        "TemplateName" => template_name,
        "SubjectPart" => subject
      }
      |> put_if_not_nil("HtmlPart", html)
      |> put_if_not_nil("TextPart", text)
      |> flatten_attrs("Template")

    params =
      opts
      |> build_opts([:configuration_set_name])
      |> Map.merge(template)

    request(:update_template, params)
  end

  @doc """
  Update an email template via V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_UpdateEmailTemplate.html
  """
  @spec update_email_template(String.t(), String.t(), String.t(), String.t()) :: ExAws.Operation.JSON.t()
  def update_email_template(template_name, subject, html, text) do
    template_content =
      %{
        "Subject" => subject
      }
      |> put_if_not_nil("Html", html)
      |> put_if_not_nil("Text", text)

    params = %{"TemplateContent" => template_content}

    request_v2(:put, "templates/#{template_name}")
    |> Map.put(:data, params)
  end

  @doc """
  Deletes an email template.
  """
  @spec delete_template(binary) :: ExAws.Operation.Query.t()
  def delete_template(template_name) do
    params = %{
      "TemplateName" => template_name
    }

    request(:delete_template, params)
  end

  @doc """
  Delete an email template via V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_DeleteEmailTemplate.html
  """
  @spec delete_email_template(binary) :: ExAws.Operation.JSON.t()
  def delete_email_template(template_name) do
    request_v2(:delete, "templates/#{template_name}")
  end

  ## Emails
  ######################

  @type email_address :: binary

  @type message :: %{
          body: %{html: %{data: binary, charset: binary}, text: %{data: binary, charset: binary}},
          subject: %{data: binary, charset: binary}
        }
  @type destination :: %{to: [email_address], cc: [email_address], bcc: [email_address]}

  @type bulk_destination :: [%{destination: destination, replacement_template_data: binary}]

  @type send_email_opt ::
          {:configuration_set_name, String.t()}
          | {:reply_to, [email_address]}
          | {:return_path, String.t()}
          | {:return_path_arn, String.t()}
          | {:source, String.t()}
          | {:source_arn, String.t()}
          | {:tags, %{(String.t() | atom) => String.t()}}

  @doc """
  Composes an email message.
  """
  @spec send_email(dst :: destination, msg :: message, src :: binary) :: ExAws.Operation.Query.t()
  @spec send_email(dst :: destination, msg :: message, src :: binary, opts :: [send_email_opt]) ::
          ExAws.Operation.Query.t()
  def send_email(dst, msg, src, opts \\ []) do
    params =
      opts
      |> build_opts([:configuration_set_name, :return_path, :return_path_arn, :source_arn, :bcc])
      |> Map.merge(format_member_attribute(:reply_to_addresses, opts[:reply_to]))
      |> Map.merge(flatten_attrs(msg, "message"))
      |> Map.merge(format_tags(opts[:tags]))
      |> Map.merge(format_dst(dst))
      |> Map.put_new("Source", src)

    request(:send_email, params)
  end

  @doc """
  Send an email via the SES V2 API, which supports list management.

  `:content` should include one of a `Raw`, `Simple`, or `Template` key.
  """
  @type destination_v2 :: %{
          optional(:ToAddresses) => [email_address],
          optional(:CcAddresses) => [email_address],
          optional(:BccAddresses) => [email_address]
        }
  @type email_field :: %{optional(:Charset) => String.t(), required(:Data) => String.t()}
  @type email_content :: %{
          optional(:Raw) => %{Data: binary},
          optional(:Simple) => %{Body: %{Html: email_field, Text: email_field}, Subject: email_field},
          optional(:Template) => %{TemplateArn: String.t(), TemplateData: String.t(), TemplateName: String.t()}
        }
  @type(
    send_email_v2_opt ::
      {:configuration_set_name, String.t()}
      | {:tags, [tag]}
      | {:feedback_forwarding_address, String.t()}
      | {:feedback_forwarding_arn, String.t()}
      | {:from_arn, String.t()}
      | {:list_management, %{ContactListName: String.t(), TopicName: String.t()}}
      | {:reply_addresses, [String.t()]},
    @spec(send_email_v2(destination_v2, email_content, email_address, [send_email_v2_opt]))
  )
  def send_email_v2(destination, content, from_email, opts \\ []) do
    data =
      prune_map(%{
        ConfigurationSetName: opts[:configuration_set_name],
        Content: content,
        Destination: destination,
        EmailTags: opts[:tags],
        FeedbackForwardingEmailAddress: opts[:feedback_forwarding_address],
        FeedbackForwardingEmailAddressIdentityArn: opts[:feedback_forwarding_arn],
        FromEmailAddress: from_email,
        FromEmailAddressIdentityArn: opts[:from_arn],
        ListManagementOptions: opts[:list_management],
        ReplyToAddresses: opts[:reply_addresses]
      })

    request_v2(:post, "outbound-emails")
    |> Map.put(:data, data)
  end

  @doc """
  Send a raw Email.
  """
  @type send_raw_email_opt ::
          {:configuration_set_name, String.t()}
          | {:from_arn, String.t()}
          | {:return_path_arn, String.t()}
          | {:source, String.t()}
          | {:source_arn, String.t()}
          | {:tags, %{(String.t() | atom) => String.t()}}

  @spec send_raw_email(binary, opts :: [send_raw_email_opt]) :: ExAws.Operation.Query.t()
  def send_raw_email(raw_msg, opts \\ []) do
    params =
      opts
      |> build_opts([:configuration_set_name, :from_arn, :return_path_arn, :source, :source_arn])
      |> Map.merge(format_tags(opts[:tags]))
      |> Map.put("RawMessage.Data", Base.encode64(raw_msg))

    request(:send_raw_email, params)
  end

  @doc """
  Send a templated Email.
  """
  @type send_templated_email_opt ::
          {:configuration_set_name, String.t()}
          | {:return_path, String.t()}
          | {:return_path_arn, String.t()}
          | {:source, String.t()}
          | {:source_arn, String.t()}
          | {:reply_to, [email_address]}
          | {:tags, %{(String.t() | atom) => String.t()}}

  @spec send_templated_email(
          dst :: destination,
          src :: binary,
          template :: binary,
          template_data :: map,
          opts :: [send_templated_email_opt]
        ) :: ExAws.Operation.Query.t()
  def send_templated_email(dst, src, template, template_data, opts \\ []) do
    params =
      opts
      |> build_opts([:configuration_set_name, :return_path, :return_path_arn, :source_arn, :bcc])
      |> Map.merge(format_member_attribute(:reply_to_addresses, opts[:reply_to]))
      |> Map.merge(format_tags(opts[:tags]))
      |> Map.merge(format_dst(dst))
      |> Map.put("Source", src)
      |> Map.put("Template", template)
      |> Map.put("TemplateData", format_template_data(template_data))

    request(:send_templated_email, params)
  end

  @doc """
  Send a templated email to multiple destinations.
  """
  @type send_bulk_templated_email_opt ::
          {:configuration_set_name, String.t()}
          | {:return_path, String.t()}
          | {:return_path_arn, String.t()}
          | {:source_arn, String.t()}
          | {:default_template_data, String.t()}
          | {:reply_to, [email_address]}
          | {:tags, %{(String.t() | atom) => String.t()}}

  @spec send_bulk_templated_email(
          template :: binary,
          source :: binary,
          destinations :: bulk_destination,
          opts :: [send_bulk_templated_email_opt]
        ) :: ExAws.Operation.Query.t()
  def send_bulk_templated_email(template, source, destinations, opts \\ []) do
    params =
      opts
      |> build_opts([:configuration_set_name, :return_path, :return_path_arn, :source_arn, :default_template_data])
      |> Map.merge(format_member_attribute(:reply_to_addresses, opts[:reply_to]))
      |> Map.merge(format_tags(opts[:tags]))
      |> Map.merge(format_bulk_destinations(destinations))
      |> Map.put("DefaultTemplateData", format_template_data(opts[:default_template_data]))
      |> Map.put("Source", source)
      |> Map.put("Template", template)

    request(:send_bulk_templated_email, params)
  end

  @doc """
  Deletes the specified identity (an email address or a domain) from the list
  of verified identities.
  """
  @spec delete_identity(binary) :: ExAws.Operation.Query.t()
  def delete_identity(identity) do
    request(:delete_identity, %{"Identity" => identity})
  end

  @type set_identity_notification_topic_opt :: {:sns_topic, binary}
  @type notification_type :: :bounce | :complaint | :delivery

  @doc """
  Sets the Amazon Simple Notification Service (Amazon SNS) topic to which
  Amazon SES will publish  delivery notifications for emails sent with given
  identity.

  Absent `:sns_topic` options cleans SnsTopic and disables publishing.

  Notification type can be on of the `:bounce`, `:complaint`, or `:delivery`.
  Requests are throttled to one per second.
  """
  @spec set_identity_notification_topic(binary, notification_type, set_identity_notification_topic_opt | []) ::
          ExAws.Operation.Query.t()
  def set_identity_notification_topic(identity, type, opts \\ []) when type in @notification_types do
    notification_type = Atom.to_string(type) |> String.capitalize()

    params =
      opts
      |> build_opts([:sns_topic])
      |> Map.merge(%{"Identity" => identity, "NotificationType" => notification_type})

    request(:set_identity_notification_topic, params)
  end

  @doc """
  Enables or disables whether Amazon SES forwards notifications as email.
  """
  @spec set_identity_feedback_forwarding_enabled(boolean, binary) :: ExAws.Operation.Query.t()
  def set_identity_feedback_forwarding_enabled(enabled, identity) do
    request(:set_identity_feedback_forwarding_enabled, %{"ForwardingEnabled" => enabled, "Identity" => identity})
  end

  @doc """
  Build message object.
  """
  @spec build_message(binary, binary, binary, binary) :: message
  def build_message(html, txt, subject, charset \\ "UTF-8") do
    %{
      body: %{
        html: %{data: html, charset: charset},
        text: %{data: txt, charset: charset}
      },
      subject: %{data: subject, charset: charset}
    }
  end

  @doc """
  Set whether SNS notifications should include original email headers or not.
  """
  @spec set_identity_headers_in_notifications_enabled(binary, notification_type, boolean) :: ExAws.Operation.Query.t()
  def set_identity_headers_in_notifications_enabled(identity, type, enabled) do
    notification_type = Atom.to_string(type) |> String.capitalize()

    request(
      :set_identity_headers_in_notifications_enabled,
      %{"Identity" => identity, "NotificationType" => notification_type, "Enabled" => enabled}
    )
  end

  @doc "Create a custom verification email template."
  @spec create_custom_verification_email_template(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: ExAws.Operation.Query.t()
  def create_custom_verification_email_template(
        template_name,
        from_email_address,
        template_subject,
        template_content,
        success_redirection_url,
        failure_redirection_url
      ) do
    request(:create_custom_verification_email_template, %{
      "TemplateName" => template_name,
      "FromEmailAddress" => from_email_address,
      "TemplateSubject" => template_subject,
      "TemplateContent" => template_content,
      "SuccessRedirectionURL" => success_redirection_url,
      "FailureRedirectionURL" => failure_redirection_url
    })
  end

  @type update_custom_verification_email_template_opt ::
          {:template_name, String.t()}
          | {:from_email_address, String.t()}
          | {:template_subject, String.t()}
          | {:template_content, String.t()}
          | {:success_redirection_url, String.t()}
          | {:failure_redirection_url, String.t()}
  @doc "Update or create a custom verification email template."
  @spec update_custom_verification_email_template(opts :: [update_custom_verification_email_template_opt] | []) ::
          ExAws.Operation.Query.t()
  def update_custom_verification_email_template(opts \\ []) do
    params =
      opts
      |> build_opts([
        :template_name,
        :from_email_address,
        :template_subject,
        :template_content
      ])
      |> maybe_put_param(opts, :success_redirection_url, "SuccessRedirectionURL")
      |> maybe_put_param(opts, :failure_redirection_url, "FailureRedirectionURL")

    request(:update_custom_verification_email_template, params)
  end

  @doc "Delete custom verification email template."
  @spec delete_custom_verification_email_template(String.t()) :: ExAws.Operation.Query.t()
  def delete_custom_verification_email_template(template_name) do
    request(:delete_custom_verification_email_template, %{"TemplateName" => template_name})
  end

  @type list_custom_verification_email_templates_opt :: {:max_results, String.t()} | {:next_token, String.t()}
  @doc "Lists custom verification email templates."
  @spec list_custom_verification_email_templates(opts :: [list_custom_verification_email_templates_opt()] | []) ::
          ExAws.Operation.Query.t()
  def list_custom_verification_email_templates(opts \\ []) do
    params = build_opts(opts, [:max_results, :next_token])
    request(:list_custom_verification_email_templates, params)
  end

  @type send_custom_verification_email_opt :: {:configuration_set_name, String.t()}
  @doc "Send a verification email using a custom template."
  @spec send_custom_verification_email(String.t(), String.t(), opts :: [send_custom_verification_email_opt] | []) ::
          ExAws.Operation.Query.t()
  def send_custom_verification_email(email_address, template_name, opts \\ []) do
    params =
      opts
      |> build_opts([:configuration_set_name])
      |> Map.put("EmailAddress", email_address)
      |> Map.put("TemplateName", template_name)

    request(:send_custom_verification_email, params)
  end

  @doc "Create a custom verification email template via the SES V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_CreateCustomVerificationEmailTemplate.html"
  @spec create_custom_verification_email_template_v2(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: ExAws.Operation.JSON.t()
  def create_custom_verification_email_template_v2(
        template_name,
        from_email_address,
        template_subject,
        template_content,
        success_redirection_url,
        failure_redirection_url
      ) do
    request_v2(:post, "/custom-verification-email-templates")
    |> Map.put(:data, %{
      "TemplateName" => template_name,
      "FromEmailAddress" => from_email_address,
      "TemplateSubject" => template_subject,
      "TemplateContent" => template_content,
      "SuccessRedirectionURL" => success_redirection_url,
      "FailureRedirectionURL" => failure_redirection_url
    })
  end

  @doc "Update an existing custom verification email template via the SES V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_UpdateCustomVerificationEmailTemplate.html"
  @spec update_custom_verification_email_template_v2(
          String.t(),
          opts :: [update_custom_verification_email_template_opt] | []
        ) ::
          ExAws.Operation.JSON.t()
  def update_custom_verification_email_template_v2(template_name, opts \\ []) do
    params =
      opts
      |> build_opts([
        :from_email_address,
        :template_subject,
        :template_content
      ])
      |> maybe_put_param(opts, :success_redirection_url, "SuccessRedirectionURL")
      |> maybe_put_param(opts, :failure_redirection_url, "FailureRedirectionURL")

    request_v2(:put, "custom-verification-email-templates/#{template_name}")
    |> Map.put(:data, params)
  end

  @doc "Deletes an existing custom verification email template via the SES V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_DeleteCustomVerificationEmailTemplate.html"
  @spec delete_custom_verification_email_template_v2(String.t()) :: ExAws.Operation.JSON.t()
  def delete_custom_verification_email_template_v2(template_name) do
    request_v2(:delete, "custom-verification-email-templates/#{template_name}")
  end

  @type list_custom_verification_email_templates_opt_v2 :: {:page_size, pos_integer} | {:next_token, String.t()}
  @doc "Lists the existing custom verification email templates via the SES V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_ListCustomVerificationEmailTemplates.html"
  @spec list_custom_verification_email_templates_v2(opts :: [list_custom_verification_email_templates_opt_v2()] | []) ::
          ExAws.Operation.JSON.t()
  def list_custom_verification_email_templates_v2(opts \\ []) do
    params = build_opts(opts, [:page_size, :next_token])
    request_v2(:get, "custom-verification-email-templates?#{URI.encode_query(params)}")
  end

  @doc "Get a custom verification email template via the SES V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_GetCustomVerificationEmailTemplate.html"
  @spec get_custom_verification_email_template_v2(String.t()) :: ExAws.Operation.JSON.t()
  def get_custom_verification_email_template_v2(template_name) do
    request_v2(:get, "custom-verification-email-templates/#{template_name}")
  end

  @doc "Send a verification email using a custom template via SES V2 API. See https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_SendCustomVerificationEmail.html"
  @spec send_custom_verification_email_v2(String.t(), String.t(), opts :: [send_custom_verification_email_opt] | []) ::
          ExAws.Operation.JSON.t()
  def send_custom_verification_email_v2(email_address, template_name, opts \\ []) do
    params =
      opts
      |> build_opts([:configuration_set_name])
      |> Map.put("EmailAddress", email_address)
      |> Map.put("TemplateName", template_name)

    request_v2(:post, "outbound-custom-verification-emails")
    |> Map.put(:data, params)
  end

  @spec test_render_email_template(String.t(), map()) :: ExAws.Operation.JSON.t()
  def test_render_email_template(template_name, template_data) do
    request_v2(:post, "templates/#{template_name}/render")
    |> Map.put(:data, %{
      "TemplateData" => format_template_data(template_data)
    })
  end

  ## Receipt Rules and Rule Sets
  ######################
  @doc "Describe the given receipt rule set."
  @spec describe_receipt_rule_set(String.t()) :: ExAws.Operation.Query.t()
  def describe_receipt_rule_set(rule_set_name) do
    request(:describe_receipt_rule_set, %{"RuleSetName" => rule_set_name})
  end

  defp format_dst(dst, root \\ "destination") do
    dst =
      Enum.reduce([:to, :bcc, :cc], %{}, fn key, acc ->
        case Map.fetch(dst, key) do
          {:ok, val} -> Map.put(acc, :"#{key}_addresses", val)
          _ -> acc
        end
      end)

    dst
    |> Map.to_list()
    |> format_member_attributes([:bcc_addresses, :cc_addresses, :to_addresses])
    |> flatten_attrs(root)
  end

  defp format_template_data(nil), do: "{}"

  defp format_template_data(template_data), do: Map.get(aws_base_config(), :json_codec).encode!(template_data)

  defp format_bulk_destinations(destinations) do
    destinations
    |> Enum.with_index(1)
    |> Enum.flat_map(fn
      {%{destination: destination} = destination_member, index} ->
        root = "Destinations.member.#{index}"

        destination
        |> format_dst("#{root}.Destination")
        |> add_replacement_template_data(destination_member, root)
        |> Map.to_list()
    end)
    |> Map.new()
  end

  defp add_replacement_template_data(destination, %{replacement_template_data: replacement_template_data}, root) do
    destination
    |> Map.put("#{root}.ReplacementTemplateData", format_template_data(replacement_template_data))
  end

  defp add_replacement_template_data(destination, _, _), do: destination

  defp format_tags(nil), do: %{}

  defp format_tags(tags) do
    tags
    |> Enum.with_index(1)
    |> Enum.reduce(%{}, fn {tag, index}, acc ->
      key = camelize_key("tags.member.#{index}")
      Map.merge(acc, flatten_attrs(tag, key))
    end)
  end

  ## Request
  ######################

  defp request(action, params) do
    action_string = action |> Atom.to_string() |> Macro.camelize()

    %ExAws.Operation.Query{
      path: "/",
      params: params |> Map.put("Action", action_string),
      service: @service,
      action: action,
      parser: &ExAws.SES.Parsers.parse/2
    }
  end

  defp request_v2(method) do
    %ExAws.Operation.JSON{
      http_method: method,
      path: @v2_path,
      service: @service
    }
  end

  defp request_v2(method, resource) do
    request_v2(method)
    |> Map.put(:path, @v2_path <> "/#{resource}")
  end

  defp build_opts(opts, permitted) do
    opts
    |> Map.new()
    |> Map.take(permitted)
    |> camelize_keys
  end

  defp maybe_put_param(params, opts, key, name) do
    case opts[key] do
      nil -> params
      value -> Map.put(params, name, value)
    end
  end

  defp format_member_attributes(opts, members) do
    opts
    |> Map.new()
    |> Map.take(members)
    |> Enum.reduce(Map.new(opts), fn entry, acc -> Map.merge(acc, format_member_attribute(entry)) end)
    |> Map.drop(members)
  end

  defp format_member_attribute(key, collection), do: format_member_attribute({key, collection})

  defp format_member_attribute({_, nil}), do: %{}

  defp format_member_attribute({key, collection}) do
    collection
    |> Enum.with_index(1)
    |> Map.new(fn {item, index} ->
      {"#{camelize_key(key)}.member.#{index}", item}
    end)
  end

  defp flatten_attrs(attrs, root) do
    do_flatten_attrs({attrs, camelize_key(root)})
    |> List.flatten()
    |> Map.new()
  end

  defp do_flatten_attrs({attrs, root}) when is_map(attrs) do
    Enum.map(attrs, fn {k, v} ->
      do_flatten_attrs({v, root <> "." <> camelize_key(k)})
    end)
  end

  defp do_flatten_attrs({val, path}) do
    {camelize_key(path), val}
  end

  defp put_if_not_nil(map, _, nil), do: map
  defp put_if_not_nil(map, key, value), do: map |> Map.put(key, value)

  defp aws_base_config(), do: ExAws.Config.build_base(@service)

  defp prune_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
