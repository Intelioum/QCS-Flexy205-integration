Rem --- eWON start section: Cyclic Section
eWON_cyclic_section:
Rem --- eWON user (start)
Rem --- eWON user (end)
End
Rem --- eWON end section: Cyclic Section
Rem --- eWON start section: Init Section
eWON_init_section:
Rem --- eWON user (start)
//################ CONFIGURATION #################
SETSYS INF, "LOAD"
SerNum$ = GETSYS INF, "SERNUM"
Username$ = "YOUR USERNAME"
Password$ = "YOUR PASSWORD"
DeviceId$= "Flexy205"
ClientID$ = "FlexyCustomer"
PublishTopic$ = "/PROD/" + DeviceId$ + "/" + SerNum$ + "/ToB/"
ReceiveTopic$ = "/PROD/" + DeviceId$ + "/" + SerNum$ + "/ToD/#"
AwsBrokerURL$ = "mqtt.qcloudserver.com"
Changepushtime% = 1000 //Timer to push only Tags that has changed
Fullpushtime% = 1 // Timer to push all values
//Select the Tag Group to publish -> 0 or 1
//Tag must be created and at least set in one of the groups.
GROUPA% = 1
GROUPB% = 1
GROUPC% = 1
GROUPD% = 1
// Do not forget to select Run > Autorun in order to have the script running at boot
//################ END CONFIGURATION ##############
CLS
//Read number of Tags
NB%= GETSYS PRG,"NBTAGS"
DIM a(NB%,2)
//Start "Try to Connect" timer
ONTIMER 1, "GOTO MqttCONNECT"
TSET 1,10
MqttCONNECT:
MQTT "OPEN", ClientID$ , AwsBrokerURL$
Mqtt "SETPARAM", "Port","1883"
MQTT "SETPARAM", "log", "1"
MQTT "SETPARAM", "username", Username$
MQTT "SETPARAM", "password", Password$
MQTT "SETPARAM", "CleanSession", "1"
MQTT "SETPARAM", "ProtocolVersion", "3.1.1"
MQTT "SETPARAM", "keepalive", "60"
MQTT "CONNECT"
MQTT "SUBSCRIBE",ReceiveTopic$,0
ONMQTT "GOTO MqttRx"
//IF No error --> Connected --> Disable Retry timer
TSET 1,0
//a = table with 2 columns : one with the negative index of the tag and the second one with 1 if the values of the tag change or 0 otherwise
IsConnected:
//Record the Tag ONCHANGE events into an array.
//Allows to post only values that have changed
FOR i% = 0 TO NB%-1
 k%=i%+1
 SETSYS Tag, "load",-i%
 a(k%,1)=-i%
 a(k%,2) = 0
 GroupA$= GETSYS TAG,"IVGROUPA"
 GroupB$= GETSYS TAG,"IVGROUPB"
 GroupC$= GETSYS TAG,"IVGROUPC"
 GroupD$= GETSYS TAG,"IVGROUPD"
 
 IF GroupA$ = "1" And GROUPA%= 1 THEN Onchange -i%, "a("+ STR$ k%+",2)= 1"
 IF GroupB$ = "1" And GROUPB%= 1 THEN Onchange -i%, "a("+ STR$ k%+",2)= 1"
 IF GroupC$ = "1" And GROUPC%= 1 THEN Onchange -i%, "a("+ STR$ k%+",2)= 1"
 IF GroupD$ = "1" And GROUPD%= 1 THEN Onchange -i%, "a("+ STR$ k%+",2)= 1"
NEXT i%
  
ONTIMER 1,"goto MqttPublishAllValue" 
ONTIMER 2, "goto MqttPublishChangedValue"
TSET 1,Fullpushtime%
TSET 2,Changepushtime%
END
//Compute the right time format for AZURE
Function GetTime$()
$a$ = Time$
$GetTime$ = $a$(7 To 10) + "-" + $a$(4 To 5) + "-" + $a$(1 To 2) + " " + $a$(12 To 13)+":"+$a$(15 To 16)+":"+$a$(18 To 19)
EndFn
//Publish just the changed tags
MqttPublishChangedValue:
counter% = 0
//Compute JSON
json$ = '{'
FOR r% = 1 TO NB%
IF a( r%,2) = 1 THEN
  a(r%,2) = 0
  negIndex% = a(r%,1)
  SETSYS Tag, "LOAD", negIndex%
  name$= GETSYS Tag, "name"
  json$ = json$ + '"' + name$+ '":"'+STR$ GETIO name$ + '",'
  counter% = counter% +1
ENDIF
NEXT r%
json$ = json$ +    '"time": "'+@GetTime$()+'"'
json$ = json$ +    '}'
IF counter% > 0 THEN
 STATUS% = MQTT("STATUS") 
 IF (STATUS% = 5) THEN  //Is Connected
  MQTT "PUBLISH",PublishTopic$,json$, 0, 0
  PRINT "[PUBLISH ONCHANGE TIMER] " + STR$ counter% + " Tags have changed detected -> Publish"
 ENDIF
ELSE
PRINT "[PUBLISH ONCHANGE TIMER] No Tag changes detected! -> Don't publish"
ENDIF
END
  
//publish all tags
MqttPublishAllValue:
counter%=0
json$ =         '{'
  FOR i% = 0 TO NB% -1
      SETSYS Tag, "load",-i%
      i$= GETSYS TAG,"Name"
      
      GroupA$= GETSYS TAG,"IVGROUPA"
      GroupB$= GETSYS TAG,"IVGROUPB"
      GroupC$= GETSYS TAG,"IVGROUPC"
      GroupD$= GETSYS TAG,"IVGROUPD"
      
      IF GroupA$ = "1" And GROUPA%= 1 THEN json$ = json$ + '"' + i$+ '":"'+STR$ GETIO i$ + '",': counter% = counter% +1
      IF GroupB$ = "1" And GROUPB%= 1 THEN json$ = json$ + '"' + i$+ '":"'+STR$ GETIO i$ + '",': counter% = counter% +1
      IF GroupC$ = "1" And GROUPC%= 1 THEN json$ = json$ + '"' + i$+ '":"'+STR$ GETIO i$ + '",': counter% = counter% +1
      IF GroupD$ = "1" And GROUPD%= 1 THEN json$ = json$ + '"' + i$+ '":"'+STR$ GETIO i$ + '",': counter% = counter% +1
      
  NEXT i%    
  json$ = json$ +    '"time": "'+ @GetTime$() +'"'
  json$ = json$ +   '}'
  
  STATUS% = MQTT("STATUS")
 //Is Connected
 IF (STATUS% = 5) THEN
   Print "[PUBLISH ALL TAGS TIMER] " + STR$ counter% + " tags selected and published"
   MQTT "PUBLISH",PublishTopic$,json$, 0, 0
 ELSE
   Print "Not connected (" + STR$ STATUS% + ")"
 ENDIF
END
MqttRx:
MqttReadNext:   
   MessageQty%=Mqtt "READ"
   IF (MessageQty%>0) Then
      MsgTopic$=MQTT "MSGTOPIC"
      MsgData$ =MQTT "MSGDATA"
      Print "Tag Data is: " + MsgData$
      Print "Tag Name is: " + MsgTopic$
        IF (MsgTopic$ = ReceiveTopic$ + "SETIO/") Then
          Print "Tag Name is: " + MsgData$.value
          Print "Tag Value is: " + MsgData$.name

        ENDIF
        IF (MsgTopic$ = ReceiveTopic$ + "SETALM/") Then
        ENDIF
      GOTO MqttReadNext
   ENDIF
END
END
Rem --- eWON user (end)
End
Rem --- eWON end section: Init Section