Rem --- eWON start section: Cyclic Section
eWON_cyclic_section:
Rem --- eWON user (start)
Rem --- eWON user (end)
End
Rem --- eWON end section: Cyclic Section
Rem --- eWON start section: Init Section
eWON_init_section:
Rem --- eWON user (start)
CLS
SETSYS INF, "LOAD"
SerNum$ = GETSYS INF, "SERNUM"
//########   CONFIG   ###############
Username$ = "YOUR USERNAME"
Password$ = "YOUR PASSWORD"
DeviceId$= "Flexy205"
ClientID$ = "YOUR CLIENT ID"
MQTTBrokerURL$ = "mqtt.qcloudserver.com"
MQTTPort$ = "1883"
TopicToPublishOn$ = "/EWON/" + ClientID$ + "/" + DeviceId$ + "/" + SerNum$ + "/ToB/"
TopicToSubscribe$ = "/EWON/" + ClientID$ + "/" + DeviceId$ + "/" + SerNum$ + "/ToD/"
MsgToPublish$ = "Hello From Flexy " + SerNum$ 
//######## END CONFIG ###############
Last_ConnStatus% = 0
CONNECTMQTT:
MQTT "OPEN", ClientID$ , MQTTBrokerURL$
MQTT "SETPARAM", "PORT", MQTTPort$ 
MQTT "SETPARAM", "username", Username$
MQTT "SETPARAM", "password", Password$
MQTT "SETPARAM", "CleanSession", "1"
MQTT "SETPARAM", "ProtocolVersion", "3.1.1"
MQTT "SETPARAM", "keepalive", "60"
MQTT "SUBSCRIBE",TopicToSubscribe$,1
SETSYS PRG,"RESUMENEXT",1
MQTT "CONNECT"
ErrorReturned% = GETSYS PRG,"LSTERR"
IF ErrorReturned% = 28 THEN @Log("[MQTT SCRIPT] WAN interface not yet ready")
SETSYS PRG,"RESUMENEXT",0
ONMQTT "GOTO MQTTRECEIVEMSG"  
ONTIMER 1, "GOTO READDATA"
TSET 1,1 // Set to check Data every 1 second
//ONTIMER 2, "GOTO CheckAlarm"
//TSET 2,1 // Set to check Alarm every 1 second
END
CheckAlarm:
EBD_String$ = "exp:$dtAR$ftT"
AlarmHistoryFile$ = ""
OPEN EBD_String$ FOR TEXT INPUT AS 1
LoopAL:
A$ = Get 1
IF A$ <> "" THEN
  AlarmHistoryFile$ = AlarmHistoryFile$ + A$
  MsgToPublish$ = AlarmHistoryFile$
  TopicToPublishOn$ = "/EWON/" + ClientID$ + "/" + DeviceId$ + "/" + SerNum$ + "/ToB/ALM/"
  @SENDDATA(TopicToPublishOn$, MsgToPublish$)
  GOTO LoopAL
ELSE
  Print "No Alarm"
ENDIF
CLOSE 1
END
READDATA:
  NB%= GETSYS PRG,"NBTAGS"
  DIM a(NB%,2)
  FOR i% = 0 TO NB% -1
    SETSYS Tag, "load",-i%
    TagName$ = GETSYS TAG,"Name"
    TagValue$ = GETSYS TAG,"TagValue"
    TagDescription$ = GETSYS TAG,"Description"
    TagServerName$ = GETSYS TAG,"ServerName"
    TagAddress$ = GETSYS TAG,"Address"
    TagType$ = GETSYS TAG,"Type"
    IF TagType$ = "0" THEN TagType$ = "Boolean"
    IF TagType$ = "1" THEN TagType$ = "Floating Point"
    IF TagType$ = "2" THEN TagType$ = "Integer"
    IF TagType$ = "3" THEN TagType$ = "DWord"
    TagAlEnabled$ = GETSYS TAG,"AlEnabled"
    TagAlBool$ = GETSYS TAG,"AlBool"
    TagAlAutoAck$ = GETSYS TAG,"AlAutoAck"
    TagAlHint$ = GETSYS TAG,"AlHint"
    TagAlHigh$ = GETSYS TAG,"AlHigh"
    TagAlLow$ = GETSYS TAG,"AlLow"
    TagAlLoLo$ = GETSYS TAG,"AlLoLo"
    TagAlHiHi$ = GETSYS TAG,"AlHiHi"
    TagAIStat$ = GETSYS TAG,"AIStat"
    TagAIType$ = GETSYS TAG,"AIType"
    TagEEN$ = GETSYS TAG,"EEN"
    TagETO$ = GETSYS TAG,"ETO"
    TagECC$ = GETSYS TAG,"ECC"
    TagESU$ = GETSYS TAG,"ESU"
    TagSEN$ = GETSYS TAG,"SEN"
    TagSTO$ = GETSYS TAG,"STO"
    TagSSU$ = GETSYS TAG,"SSU"
    json$ = '{'
    json$ = json$ + '"name":"' + TagName$ + '",'
    json$ = json$ + '"value":"' + TagValue$ + '",'
    json$ = json$ + '"Description":"' + TagDescription$ + '",'
    json$ = json$ + '"ServerName":"' + TagServerName$ + '",'
    json$ = json$ + '"Address":"' + TagAddress$ + '",'
    json$ = json$ + '"Type":"' + TagType$ + '",'
    IF TagAlEnabled$ = "1" THEN
    json$ = json$ + '"AlEnabled":"' + TagAlEnabled$ + '",'
    json$ = json$ + '"AlBool":"' + TagAlBool$ + '",'
    json$ = json$ + '"AlAutoAck":"' + TagAlAutoAck$ + '",'
    json$ = json$ + '"AlHint":"' + TagAlHint$ + '",'
    json$ = json$ + '"AlHigh":"' + TagAlHigh$ + '",'
    json$ = json$ + '"AlLow":"' + TagAlLow$ + '",'
    json$ = json$ + '"AlLoLo":"' + TagAlLoLo$ + '",'
    json$ = json$ + '"AlHiHi":"' + TagAlHiHi$ + '",'
    json$ = json$ + '"AIStat":"' + TagAIStat$ + '",'
    json$ = json$ + '"AIType":"' + TagAIType$ + '",'
    json$ = json$ + '"EEN":"' + TagEEN$ + '",'
    json$ = json$ + '"ETO":"' + TagETO$ + '",'
    json$ = json$ + '"ECC":"' + TagECC$ + '",'
    json$ = json$ + '"ESU":"' + TagESU$ + '",'
    json$ = json$ + '"SEN":"' + TagSEN$ + '",'
    json$ = json$ + '"STO":"' + TagSTO$ + '",'
    json$ = json$ + '"SSU":"' + TagSSU$ + '",'
    ENDIF
    json$ = json$ + '"time": "'+ @GetTime$() +'"'
    json$ = json$ + '}'
    MsgToPublish$ = json$
    TopicToPublishOn$ = "/EWON/" + ClientID$ + "/" + DeviceId$ + "/" + SerNum$ + "/ToB/" + TagName$ + "/"
    @SENDDATA(TopicToPublishOn$, MsgToPublish$)
  NEXT i%
END
MQTTRECEIVEMSG:
   MessageQty%=Mqtt "READ"  //Return the number of pending messages
   IF (MessageQty%>0) Then
      indexElement% = 0
      MsgTopic$= MQTT "MSGTOPIC"
      MsgData$ = MQTT "MSGDATA"
      JSONLoop:
        msgType$ = @ParseSimpleJson$(MsgData$,"msgType",indexElement%)
        IF msgType$ = "ELEMENT DOES NOT EXIST" THEN GOTO EndLoop
        IF msgType$ = "setValue" THEN GOSUB SETVALUE
        IF msgType$ = "setAttribute" THEN GOSUB SETATTRIBUTE
        IF msgType$ = "setAlarm" THEN GOSUB SETALARM
        indexElement% = indexElement% +1
        IF indexElement% < 1000 THEN GOTO JSONLoop
      EndLoop:
      @Log("[MQTT SCRIPT] Message '"+ MsgData$ + "' received on topic " +MsgTopic$)
      GOTO MQTTRECEIVEMSG
   ENDIF
END
SETVALUE:
    TagName$ =@ParseSimpleJson$(MsgData$,"name",indexElement%)
    TagValue$ =@ParseSimpleJson$(MsgData$,"value",indexElement%)
    SETIO TagName$,TagValue$
RETURN

SETATTRIBUTE:
    TagName$ =@ParseSimpleJson$(MsgData$,"name",indexElement%)
    AttributeName$ =@ParseSimpleJson$(MsgData$,"attribute",indexElement%) 
    AttributeValue$ =@ParseSimpleJson$(MsgData$,"value",indexElement%)
    SETSYS TAG, "LOAD", TagName$
    SETSYS TAG, AttributeName$, AttributeValue$
    SETSYS TAG, "SAVE"
RETURN

SETALARM:
    
RETURN
FUNCTION SENDDATA($TopicToPublishOn$, $MsgToPublish$)
ConnStatus% = MQTT "STATUS"
IF Last_ConnStatus% <> ConnStatus% THEN
  IF ConnStatus% = 5 THEN
    @Log("[MQTT SCRIPT] Flexy connected to Broker")
  ELSE
    @Log("[MQTT SCRIPT] Flexy disconnected from Broker")
  ENDIF
  Last_ConnStatus% = ConnStatus%
ENDIF
IF ConnStatus% = 5 THEN
  SETSYS PRG,"RESUMENEXT",1
  MQTT "PUBLISH",  TopicToPublishOn$ , MsgToPublish$, 0,0
  PRINT "[MQTT SCRIPT] Message published to the MQTT broker"
  ErrorReturned = GETSYS PRG,"LSTERR"
  IF ErrorReturned=28 THEN
   MQTT "CLOSE"
   GOTO CONNECTMQTT
  ENDIF
ELSE
  @Log("[MQTT SCRIPT] Flexy not connected")
ENDIF
ENDFN
FUNCTION Log($Msg$)
  //LOGEVENT  $Msg$ ,100
  //PRINT $Msg$
ENDFN
Function GetTime$()
$a$ = Time$
$GetTime$ = $a$(7 To 10) + "-" + $a$(4 To 5) + "-" + $a$(1 To 2) + " " + $a$(12 To 13)+":"+$a$(15 To 16)+":"+$a$(18 To 19)
EndFn
Function ParseSimpleJson$($inputJson$, $key$, $CollectionIndex%)
     $StartIndex% = 1
     FOR $i% = 0 TO 10000
       $StartBracketPos% = INSTR $StartIndex%, $inputJson$, '{'
       IF $StartBracketPos% = 0 THEN
         $ParseSimpleJson$ = "ELEMENT DOES NOT EXIST"
         RETURN
       ENDIF
       IF $CollectionIndex% > 0 THEN
         $CollectionIndex% = $CollectionIndex% - 1
         $StartIndex% = $StartBracketPos% + 1
         //Find next element
       ELSE          
           IF $StartBracketPos% = 0 THEN
             $ParseSimpleJson$ = "JSON FORMAT NOT VALID"
             RETURN
           ELSE        
             $EndBracketPos% = INSTR $StartBracketPos%, $inputJson$, '}'
             $ELEMENTString$ = $inputJson$($StartBracketPos% TO $EndBracketPos%)
             $ParseSimpleJson$ = @ExtractKeyValue$($ELEMENTString$, $key$)
             RETURN
           ENDIF            
       ENDIF
     NEXT $i%  
EndFn
Function ExtractKeyValue$($ElementString$, $Key$)

  $StartPosKey% = INSTR 1,$ElementString$, $key$
  $StartPosKeyColumn% = INSTR $StartPosKey% ,$ElementString$, ":"
  $EndPosKeyColumn% = INSTR $StartPosKeyColumn% ,$ElementString$, ','

  $StartPosKeyColumn% = $StartPosKeyColumn% + 1
  $EndPosKeyColumn% = $EndPosKeyColumn% - 1

  IF $EndPosKeyColumn% = -1 THEN //Last key
    $EndPosKeyColumn% = LEN $ElementString$ - 1
  ENDIF

  $KeyValue$ = $ElementString$($StartPosKeyColumn% TO $EndPosKeyColumn%)
   $KeyValue$ = LTRIM $KeyValue$
   $KeyValue$ = RTRIM $KeyValue$

  IF $KeyValue$(1) = '"' THEN //is a string value -> remove quote
    $EndKeyValue = LEN $KeyValue$ - 1
    $ExtractKeyValue$ = $KeyValue$(2 TO $EndKeyValue)
  ELSE
    $ExtractKeyValue$ = $KeyValue$ 
  ENDIF
EndFn

Rem --- eWON user (end)
End
Rem --- eWON end section: Init Section