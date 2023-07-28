using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$SLACK_HOOK_URL = $env:SLACK_HOOK_URL

$SLACK_MSG_TEMPLATE = @"
{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "DigiKoo Cloud Azure Alert"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "REPLACE_ME_SUMMARY_MARKER"
            }
        },
        {
            "type": "divider"
        }
    ],
    "attachments": [
        {
            "blocks": [
                {
                    "type": "section",
                    "text": {
                        "type": "mrkdwn",
                        "text": "REPLACE_ME_FULL_BODY_MARKER"
                    }
                }
            ]
        }
    ]
}
"@ | convertfrom-json

$alert = $request.body

$SLACK_MSG_TEMPLATE.blocks[0].text.text = $alert.data.essentials.alertRule+": The pod $($alert.data.alertContext.condition.allOf[0].dimensions[0].value) has been killed\n"
$SLACK_MSG_TEMPLATE.blocks[2].text.text = "Please find log query result by the link:"
$SLACK_MSG_TEMPLATE.attachments[0].blocks[0].text.text = $alert.data.alertContext.condition.allOf[0].linkToFilteredSearchResultsUI

Invoke-WebRequest -Method POST -ContentType "application/json" -Body ($SLACK_MSG_TEMPLATE|convertto-json -Depth 10) -Uri $env:SLACK_HOOK_URL

        