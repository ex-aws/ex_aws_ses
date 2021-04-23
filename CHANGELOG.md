v2.2.0
  - Add CRUD actions on contact list and contact resources by j4p3 
  - Add v2 API's [SendEmail](https://docs.aws.amazon.com/ses/latest/APIReference-V2/API_SendEmail.html) action by j4p3
  
v2.1.1
  - Added support of `ReplyToAddresses.member.N` option to [SendBulkTemplatedEmail](https://docs.aws.amazon.com/ses/latest/APIReference/API_SendBulkTemplatedEmail.html) action by @flyrboy96
  - Spec improvements by @flyrboy96

v2.1.0
  - Added support of [CreateTemplate](https://docs.aws.amazon.com/ses/latest/APIReference/API_CreateTemplate.html) action by @themerch
  - Added support of [DeleteTemplate](https://docs.aws.amazon.com/ses/latest/APIReference/API_DeleteTemplate.html) action by @themerch
  - Added support of [SendBulkTemplatedEmail](https://docs.aws.amazon.com/ses/latest/APIReference/API_SendBulkTemplatedEmail.html) action by @themerch
  -
v2.0.2
  - Added support for [SendTemplatedEmail](https://docs.aws.amazon.com/ses/latest/APIReference/API_SendTemplatedEmail.html) action with exception for two optional parameters: `TemplateArn` and `ReplyToAddresses.member.N`. by @xfumihiro
  - Fixed wrong key in destination typespec by @kalys
  - Fixed broken typespec contracts

v2.0.1

  - Improved Mix configuration

v2.0

  - Major Project Split. Please see the main ExAws repository for previous changelogs.
