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

$alertLevel = switch ($alert.data.essentials.severity) {
    "Sev0" { "Critical" }
    "Sev1" { "Error" }
    "Sev2" { "Warning" }
    "Sev3" { "Informational" }
    Default { "Verbose"}
}

$SLACK_MSG_TEMPLATE.blocks[0].text.text = $alertLevel+": "+$alert.data.essentials.alertRule+": "+$alert.data.alertContext.condition.allOf[0].dimensions[0].value
$SLACK_MSG_TEMPLATE.blocks[2].text.text = "Please find more details by the link:"

switch ($alert.data.alertContext.conditionType) {
    "LogQueryCriteria" {  
        $SLACK_MSG_TEMPLATE.attachments[0].blocks[0].text.text = $alert.data.alertContext.condition.allOf[0].linkToFilteredSearchResultsUI
    }
    "SingleResourceMultipleMetricCriteria" {
        $SLACK_MSG_TEMPLATE.attachments[0].blocks[0].text.text = $alert.data.alertContext.condition.allOf[0].metricName+" is "+$alert.data.alertContext.condition.allOf[0].operator+" "+$alert.data.alertContext.condition.allOf[0].metricValue
    }
    Default {
        $SLACK_MSG_TEMPLATE.attachments[0].blocks[0].text.text = "Unrecongnized type of alert. Please check the function app logs."
    }
}

write-host "==============Alert Body======================"
write-host ($alert | convertto-json -Depth 10)

Invoke-WebRequest -Method POST -ContentType "application/json" -Body ($SLACK_MSG_TEMPLATE|convertto-json -Depth 10) -Uri $env:SLACK_HOOK_URL
write-host "===============SLACK========================="
write-host ($SLACK_MSG_TEMPLATE | convertto-json -Depth 10)
        