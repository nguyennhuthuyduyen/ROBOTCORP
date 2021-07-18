*** Settings ***
Documentation   Template robot main suite.
...     I using this to get cert advance
...     This is the second time I write a robotcorp
Library   RPA.Browser.Selenium
Library   RPA.HTTP
Library   RPA.Tables
Library   Collections
Library   RPA.PDF
Library   RPA.Archive
Library   RPA.FileSystem


*** Variables ***
${popup}            //div[contains(@class, 'modal') and contains(@style, 'display: none')]
${input_legs}       //input[contains(@class, 'form-control') and contains(@min, '1')]
${alert_danger}     //div[contains(@class, 'alert-danger')]
${robot_image}      //div[contains(@id, 'robot-preview-image')]

# +
*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orders}=  Read Table From Csv    orders.csv   header=True
    [Return]  ${orders}

Close the annoying modal
    ${Status}=   Run Keyword And Return Status    Page Should Not Contain Element    ${popup}
    Run Keyword If    ${Status}       Click Button        //button[contains(@class, 'btn-dark')]
    
Fill the form
    [Arguments]   ${row}
    Select From List By Value    id:head    ${row}[Head]
    ${body}=   Set Variable   ${row}[Body]
    Click Element    id:id-body-${body}
    Input Text    ${input_legs}    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    
Preview the robot
    Click Button   id:preview
    Wait Until Page Contains Element    //div[contains(@id, 'robot-preview-image')]

Submit the order
    Click Button Order
    ${status}=     Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    Run Keyword If    ${status}    Try again if keyword failed    Click Button Order
    #Close the annoying modal

Try again if keyword failed
    [Arguments]    ${keyword}
    Wait Until Keyword Succeeds    10x    1 sec    ${keyword}
    
Click Button Order
    Click Button    id:order

Click Button Order Another
    Click Element    id:order-another
    
Go to order another robot
    ${is_another}=   Run Keyword And Return Status    Page Should Contain Element    id:order-another
    Run Keyword If    ${is_another}    Try again if keyword failed    Click Button Order Another

Store the receipt as a PDF file
    [Arguments]     ${order_number}
    ${pdf}=    Set Variable     ${CURDIR}${/}output${/}receipts${/}receipt_${order_number}.pdf
    ${status}=     Run Keyword And Return Status    Page Should Contain Element    ${alert_danger}
    Run Keyword If    ${status}    Try again if keyword failed    Click Button Order
    Wait Until Element Is Visible    id:receipt
    ${receipt_htmlt}=   Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_htmlt}    ${pdf}
    [Return]     ${pdf}

Take a screenshot of the robot
    [Arguments]        ${order_number}
    ${screenshot}=    Set Variable     ${CURDIR}${/}output${/}robot_images${/}receipt_${order_number}.png
    Screenshot    ${robot_image}    ${screenshot}
    [Return]     ${screenshot}
    
Embed the robot screenshot to the receipt PDF file
    [Arguments]        ${screenshot}    ${pdf}
    ${file}=   Create List
    Append To List      ${file}    ${screenshot}   ${pdf}
    Open Pdf     ${pdf}
    Add Files To Pdf    ${file}     ${pdf}
    Close Pdf  ${pdf}
    
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    receipts.zip
    
# -

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close Browser
