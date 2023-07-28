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

$SLACK_MSG_TEMPLATE.blocks[0].text.text = "The pod $($alert.data.alertContext.condition.allOf[0].dimensions[0].value) has been killed"
$SLACK_MSG_TEMPLATE.attachments[0].blocks[0].text.text = $alert.data.alertContext.condition.allOf[0] | convertto-json  -Depth 10

write-host $SLACK_MSG_TEMPLATE.attachments[0].blocks[0].text.text
write-host $SLACK_MSG_TEMPLATE.blocks[0].text.text

Invoke-WebRequest -Method POST -Headers @{"Content-Type" = "application/json"} -Body ($SLACK_MSG_TEMPLATE|convertto-json -Depth 10) -Uri $env:SLACK_HOOK_URL
#Extract projected fields from Log Search Alert
# $computer = $alert.body.data.alertContext.SearchResults.tables.rows[0]
# $svcname = $alert.body.data.alertContext.SearchResults.tables.rows[1]
# $svcstate = $alert.body.data.alertContext.SearchResults.tables.rows[2]
# $svcdisplayname = $alert.body.data.alertContext.SearchResults.tables.rows[3]
# $TimeGenerated = $alert.body.data.alertContext.SearchResults.tables.rows[4]

# write-host "Computer" $computer "svc name" $svcname "svcstate" $svcstate "svc displayname" $svcdisplayname "TimeGenerated" $timegenerated
        