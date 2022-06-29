defmodule ExAws.SES do
  import ExAws.Utils, only: [camelize_key: 1, camelize_keys: 1]

  @moduledoc """
  Operations on AWS SES

  http://docs.aws.amazon.com/ses/latest/APIReference/Welcome.html
  """

  @notification_types [:bounce, :complaint, :delivery]

  @doc "Verifies an email address"
  @spec verify_email_identity(email :: binary) :: ExAws.Operation.Query.t()
  def verify_email_identity(email) do
    request(:verify_email_identity, %{"EmailAddress" => email})
  end

  @type list_identities_opt ::
          {:max_items, pos_integer}
          | {:next_token, String.t()}
          | {:identity_type, String.t()}

  @type tag :: %{Key: String.t(), Value: String.t()}

  @doc "List identities associated with the AWS account"
  @spec list_identities(opts :: [] | [list_identities_opt]) :: ExAws.Operation.Query.t()
  def list_identities(opts \\ []) do
    params = build_opts(opts, [:max_items, :next_token, :identity_type])
    request(:list_identities, params)
  end

  @doc "Fetch identities verification status and token (for domains)"
  @spec get_identity_verification_attributes([binary]) :: ExAws.Operation.Query.t()
  def get_identity_verification_attributes(identities) when is_list(identities) do
    params = format_member_attribute({:identities, identities})
    request(:get_identity_verification_attributes, params)
  end

  @type list_configuration_sets_opt ::
          {:max_items, pos_integer}
          | {:next_token, String.t()}

  @doc "Fetch configuration sets associated with AWS account"
  @spec list_configuration_sets() :: ExAws.Operation.Query.t()
  @spec list_configuration_sets(opts :: [] | [list_configuration_sets_opt]) :: ExAws.Operation.Query.t()
  def list_configuration_sets(opts \\ []) do
    params = build_opts(opts, [:max_items, :next_token])
    request(:list_configuration_sets, params)
  end

  ## Templates
  ######################

  @doc """
  Create an email template.
  """
  @type create_template_opt :: {:configuration_set_name, String.t()}
  @spec create_template(binary, binary, binary, binary, opts :: [create_template_opt]) :: ExAws.Operation.Query.t()
  def create_template(template_name, subject, html, text, opts \\ []) do
    template = %{
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
  Delete an email template.
  """
  @spec delete_template(binary) :: ExAws.Operation.Query.t()
  def delete_template(template_name) do
    params = %{
      "TemplateName" => template_name
    }

    request(:delete_template, params)
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

  @doc "Composes an email message"
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
      |> camelize_keys
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
          | {:tags, %{(String.t() | atom) => String.t()}}

  @spec send_templated_email(
          dst :: destination,
          src :: binary,
          template :: binary,
          template_data :: binary,
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
          | {:default_tags, [tag]}

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
      |> Map.merge(format_tags(opts[:default_tags], "default_tags"))
      |> Map.merge(format_bulk_destinations(destinations))
      |> Map.put("DefaultTemplateData", format_template_data(opts[:default_template_data]) )
      |> Map.put("Source", source)
      |> Map.put("Template", template)

    request(:send_bulk_templated_email, params)
  end

  @doc "Deletes the specified identity (an email address or a domain) from the list of verified identities."
  @spec delete_identity(binary) :: ExAws.Operation.Query.t()
  def delete_identity(identity) do
    request(:delete_identity, %{"Identity" => identity})
  end

  @type set_identity_notification_topic_opt :: {:sns_topic, binary}
  @type notification_type :: :bounce | :complaint | :delivery

  @doc """
  Sets the Amazon Simple Notification Service (Amazon SNS) topic to which Amazon SES will publish  delivery
  notifications for emails sent with given identity.
  Absent `sns_topic` options cleans SnsTopic and disables publishing.

  Notification type can be on of the :bounce, :complaint or :delivery.
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

  @doc "Enables or disables whether Amazon SES forwards notifications as email"
  @spec set_identity_feedback_forwarding_enabled(boolean, binary) :: ExAws.Operation.Query.t()
  def set_identity_feedback_forwarding_enabled(enabled, identity) do
    request(:set_identity_feedback_forwarding_enabled, %{"ForwardingEnabled" => enabled, "Identity" => identity})
  end

  @doc "Build message object"
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

  @doc "Set whether SNS notifications should include original email headers or not"
  @spec set_identity_headers_in_notifications_enabled(binary, notification_type, boolean) :: ExAws.Operation.Query.t()
  def set_identity_headers_in_notifications_enabled(identity, type, enabled) do
    notification_type = Atom.to_string(type) |> String.capitalize()

    request(
      :set_identity_headers_in_notifications_enabled,
      %{"Identity" => identity, "NotificationType" => notification_type, "Enabled" => enabled}
    )
  end

  defp format_dst(dst, root \\ "destination") do
    dst = Enum.reduce([:to, :bcc, :cc], %{}, fn key, acc ->
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

  defp format_template_data(template_data), do: Poison.encode!(template_data)

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

  defp format_tags(nil, _), do: %{}

  defp format_tags(tags, param_name \\ "tags") do
    tags
    |> Enum.with_index(1)
    |> Enum.reduce(%{}, fn {tag, index}, acc ->
      key = camelize_key("#{param_name}.member.#{index}")
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
      service: :ses,
      action: action,
      parser: &ExAws.SES.Parsers.parse/2
    }
  end

  defp build_opts(opts, permitted) do
    opts
    |> Map.new()
    |> Map.take(permitted)
    |> camelize_keys
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
end
