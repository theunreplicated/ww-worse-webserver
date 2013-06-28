unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,Scktcomp;

type
reqtype=record
mode:string;
url_request:string;
end;
arrayofstring=array of string;
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure sendheader(header:string;Socket:TCustomWinSocket);
    procedure sendresponsestatus(status:integer;Socket:TCustomWinSocket);
    procedure sendContent(content:string;Socket:TCustomWinSocket);
    function Readfile(FileName:string):string;
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  Form1: TForm1;
  store_commands:array of string;
  store_file:array of string;
  store_mode:array of string;
implementation
uses Math;

{$R *.DFM}
function split_str(split_char:string;text:string):arrayofstring;
var stringar:arrayofstring;lookup_mode:string;current_text:string;posi:integer;delete_pos,copy_pos,lastpos:integer;
begin
current_text:=text;
while(pos(split_char,current_text)>0)do
begin
setlength(stringar,length(stringar)+1);
lastpos:=pos(split_char,current_text);
copy_pos:=pos(split_char,current_text);
delete_pos:=pos(split_char,current_text);
if(copy_pos<=1)then
begin
 copy_pos:=copy_pos+1;
 end;
stringar[length(stringar)-1]:=copy(current_text,1,copy_pos-1);
// showmessage(copy(current_text,delete_pos+1,length(current_text)));
current_text:=copy(current_text,delete_pos+1,length(current_text));
//showmessage(current_text+inttostr(pos(split_char,current_text)));
end;

setlength(stringar,length(stringar)+1);
stringar[length(stringar)-1]:=current_text;
result:=stringar;
end;

function interpret_headers1st(header1st:string):reqType;
var hc,until_text:String;pchar:integer;mode:String;http_statement_pos:integer;url_request:string;
begin
hc:=header1st;
if(copy(hc,1,3)='GET')then
begin
pchar:=3;mode:='GET';
end
else if(copy(hc,1,4)='POST')then
begin
pchar:=4;  mode:='POST';//TODO(seb) vllt. implement post
end;

until_text:='HTTP';
http_statement_pos:=pos(until_text,hc);
url_request:=copy(hc,pchar+1,pos(until_text,hc)-length(until_text));
result.mode:=mode;
result.url_request:=url_request;


end;
procedure TForm1.ServerClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
  MSG: String;i,found:integer;lookup_mode:string;foundary_statt_boundary:string;rest_anfrage_q,res,first_str,firstfilepart:string;splitted_url_req:arrayofstring;splitted:arrayofstring;firststlineprops:reqType; nl,FileName:string;myFile:TextFile;                        //delphitreff socket-erklärung
begin
  //Der Text wird in der Variable MSG gespeichert
  MSG := Socket.ReceiveText;
   nl:=#13#10;                      //auf ../ achten
  //Der Text wird einem MemoFeld hinzugefügt
 splitted:=split_Str(#13#10,MSG);
 firststlineprops:=interpret_headers1st(splitted[0]);
 //socket.SendText('HTTP/1.1 200'+nl+'Connection: Close'+nl+nl+memo1.Lines.GetText);
 sendresponsestatus(200,Socket);
 sendheader('Content-Type: text/html',Socket);


//read file

 splitted_url_req:=split_str('/',firststlineprops.url_request);
//showmessage(splitted_url_Req[2]+inttostr(length(splitted_url_Req)));
rest_anfrage_q:='';
   foundary_statt_boundary:='';
   firstfilepart:='';
 if(length(splitted_url_req)>=1)then
 begin


     first_str:=splitted_url_req[1];
      //check ob first string in file_array vorhanden
      for i:=0 to length(store_commands)-1 do
      begin
      //showmessage(store_commands[i]);
       if(store_commands[i]=first_str)then
       begin
      // showmessage(first_str);
       found:=i;
       foundary_statt_boundary:=inttostr(i);
       break;
      end;
      end;
      //if not(foundary_statt_boundary='')then
      begin
     firstfilepart:=store_file[found];


     if(length(splitted_url_req)>=2)then
     begin
      //TODO:fix
     for i:=2 to length(splitted_url_req)-1 do
     begin
     rest_anfrage_q:=rest_anfrage_q+'/'+splitted_url_req[i];
       //showmessage(rest_anfrage_q);
      end;
       end;
      showmessage('FILE:'+firstfilepart+rest_anfrage_q);
      end;
      //else
     // begin
          //showmessage('existiert nicht'+first_str);
      //end;
      end;//Debug:::::::::::::::::::::::::::blub.cf nicht hier i->bedingung trifft nicht zu
      if not(foundary_statt_boundary='')then
     begin
     lookup_mode:=store_mode[strtoint(foundary_statt_boundary)];



//fileName:=firststlineprops.url_request;
  fileName:=firstfilepart+rest_anfrage_q;
   //showmessage('sdsd'+fileName);
  if(lookup_mode='FILE')then
  begin
  if(fileexists(fileName))then
  begin
 AssignFile(myFile, FileName);
while not Eof(myFile) do
   begin
    ReadLn(myFile, res);
    sendContent(res,Socket);
   end;
//[/read file]
   end;
end
else
begin       //var
sendCOntent(store_file[strtoint(foundary_statt_boundary)],socket);

end;

   end
   else
   begin
   sendresponsestatus(404,socket);
   sendHEader('Content-Type:text/html',socket);
   sendContent('Not Found',socket);

   end;
 socket.Close;
end;
procedure TForm1.sendContent(content:string;Socket:TCustomWinSocket);
begin
socket.sendtext(#13#10);//=nl
socket.sendtext(content+memo1.lines.GetText);
end;
procedure TForm1.sendheader(header:string;Socket:TCustomWinSocket);
var nl:string;
begin
nl:=#13#10;
socket.SendText(header+nl);
end;
procedure TForm1.sendresponsestatus(status:integer;Socket:TCustomWinSocket);
begin
socket.sendtext('HTTP/1.1 '+inttostr(status));

end;
procedure serveDirectoryorFile(alias:String;directory:string);
begin
setlength(store_commands,length(store_commands)+1);
SetLength(store_file,length(store_file)+1);
SetLength(store_mode,length(store_mode)+1);
store_commands[length(store_commands)-1]:=alias;
store_file[length(store_file)-1]:=directory;
store_mode[length(store_mode)-1]:='FILE';
//Egal sollte eigentlich genau derselbe key sein
end;
procedure serveString(alias:String;serve_Text:String);
begin
setlength(store_commands,length(store_commands)+1);
SetLength(store_file,length(store_file)+1);
SetLength(store_mode,length(store_mode)+1);
store_commands[length(store_commands)-1]:=alias;
store_file[length(store_file)-1]:=serve_Text;
store_mode[length(store_mode)-1]:='STRING';//TODO(sebbo):konstanten

end;

procedure TForm1.Button1Click(Sender: TObject);
var Socket: TServerSocket;
begin
Socket := TServerSocket.Create(Form1);

  //Zuweisen eines Portes zB 10024
  Socket.Port := 10024;
  serveDirectoryorFile('blub.cf','Unit1.pas');
   Socket.OnClientRead:=ServerClientRead;



  //Folgende Zeile bräuchte ein TClientSocket noch:
  //Socket.Host := '127.0.0.1';
	  
  //In den Listening-Status gehen bzw connecten
  Socket.Open;
end;   //brauche ma nimmi
function TForm1.Readfile(FileName:string):string;
var myFile:TextFile;text:string;res:string;
begin                 //http://www.delphibasics.co.uk/Article.asp?Name=Files
  res:='';
 AssignFile(myFile, FileName);
while not Eof(myFile) do
   begin
    ReadLn(myFile, text);
    res:=res+text;
   end;

result:=res;
end;
end.
