unit resource.json;

interface

uses Json;

type
  IJsonToClass = interface
    ['{490128B6-E39E-4FC6-B78B-67EBFBA06DFF}']
    /// <summary> Informa o nome da classe mãe da estrutura JSON </summary>
    function setClassRoot(const value : string) : IJsonToClass;
    /// <summary> Converte um Json em classes </summary>
    function Convert(jsonString : string) : string;
  end;

  TJSonToClass = class(TInterfacedObject, IJsonToClass)
  private
    FUnitName : string;
    FClassRoot : string;
    /// <summary> Monta a parte estrutural superior da unit </summary>
    function generateType(const className : string; value : TJSONValue) : string;
    /// <summary> Monta a parte de funções inferior da unit </summary>
    function generateImplementation(const className : string; value : TJSONValue) : string;

    /// <summary> Retorna a forma de limpeza de memória dependendo do projeto </summary>
    function ClearMemory(varString : string) : string;

    function ColumnType(const value : TJSONPair) : string;
  public
    class function new(unitName : string) : IJsonToClass;
    constructor Create(unitName : string);
    destructor Destroy; override;

    /// <summary> Nome da Unit </summary>
    property unitName : string read FUnitName;
    /// <summary> Informa o nome da classe mãe da estrutura JSON </summary>
    property classRoot : string read FClassRoot;

    /// <summary> Informa o nome da classe mãe da estrutura JSON </summary>
    function setClassRoot(const value : string) : IJsonToClass;

    /// <summary> Converte um Json em classes </summary>
    function Convert(jsonString : string) : string;
  end;

/// <summary> Retorna a quantidade de espaço da tabulação </summary>
function space(tab : integer = 1) : string;

implementation

uses
  System.SysUtils, System.Classes;

/// <summary> Retorna a quantidade de espaço da tabulação </summary>
function space(tab : integer) : string;
var x: Integer;
begin
  if (tab <= 0) then
    tab := 1;
  result := '';

  for x := 0 to tab - 1 do
    result := result +' ';
end;

{ TJSonToClass }

function TJSonToClass.ClearMemory(varString: string): string;
begin
  if (unitName.ToLower.Contains('mercurio')) then
    result := 'myFreeAndNil('+ varString +');'
  else
    result := varString +'.Free;';
end;

function TJSonToClass.ColumnType(const value: TJSONPair): string;
var temp, tempFloat : string;
    obj : TJSONObject;
    arr : TJSONArray;
begin
  result := 'string';
  if (value = nil) then
    exit;

  temp := value.JsonValue.ToString;

  if (Copy(temp, 1, 1) = '"') then
    result := 'string'
  else if (Copy(temp, 1, 1) = '{') then
  begin
    obj := TJSONObject(TJSONObject.ParseJSONValue(temp));
    if (obj <> nil) then
    begin
      obj.Free;
      result := 'TJSONObject';
      exit;
    end;
  end
  else if (Copy(temp, 1, 1) = '[') then
  begin
    arr := TJSONArray(TJSONObject.ParseJSONValue(temp));
    if (arr <> nil) then
    begin
      arr.Free;
      result := 'TJSONArray';
      exit;
    end;
  end
  else if (strToIntDef(temp, -99991) <> -99991) then
    result := 'integer'
  else
  begin
    tempFloat := StringReplace(temp, '.', ',', [rfReplaceAll]);
    if (StrToFloatDef(tempFloat, -99991) <> -99991) then
      result := 'double';
  end;
end;

function TJSonToClass.Convert(jsonString: string): string;
var json : TJSONValue;
    className, comentario, usesTxt : string;
begin
  result := '';
  jsonString := Trim(jsonString);
  if (jsonString = '') then
    exit;

  try
    if (Copy(jsonString, 1, 1) = '{') then
      json := TJSONObject(TJSONObject.ParseJSONValue(jsonString))
    else if (Copy(jsonString, 1, 1) = '[') and (TJSONArray(TJSONObject.ParseJSONValue(jsonString)).Count > 0) then
      json := TJSONArray(TJSONObject.ParseJSONValue(jsonString))
    else
      exit;
  except

  end;

  className := FClassRoot;

  {$IFDEF RELEASE}
    comentario := '{' +sLineBreak+
      space(2) + 'Developer: Douglas Colombo' +sLineBreak+
      space(2) + 'Contact: (51) 99550-2636' +sLineBreak+
      space(2) + 'Mail: douglascolombo09@gmail.com' +sLineBreak+
      space(2) + 'Version: 1.0.0.1' +sLineBreak+
      '}' +sLineBreak+sLineBreak;
  {$ELSE}
  {$ENDIF}

  result := '';
  result := result + generateType(className, json); //gera type

  result := result +
    sLineBreak+
    space(2) + 'end;' +sLineBreak+
    sLineBreak+
    'implementation' +sLineBreak+
    sLineBreak;

  result := result + 'uses System.SysUtils;' +sLineBreak+sLineBreak;
  result := result + generateImplementation(className, json);
  result := result +sLineBreak+sLineBreak+ 'end.';

  if (pos('TList', result) > 0) then
    usesTxt := 'System.Generics.Collections, Json;'
  else
    usesTxt := 'Json;';
  if (unitName.ToLower.Contains('mercurio')) then
    usesTxt := 'uses mercurio.api.functions, ' + usesTxt
  else
    usesTxt := 'uses ' + usesTxt;

  result := 'unit '+ FUnitName +';'+sLineBreak+
    sLineBreak+
    comentario +
    'interface'+sLineBreak+
    sLineBreak+
    usesTxt +sLineBreak+
    sLineBreak+
    'type'+sLineBreak + result;
end;

constructor TJSonToClass.Create(unitName : string);
begin
  if (trim(unitName) = '') then
    FUnitName := 'my.unit'
  else
    FUnitName := unitName;
  FClassRoot := 'TRoot';
end;

destructor TJSonToClass.Destroy;
begin

  inherited;
end;

function TJSonToClass.generateImplementation(const className: string; value: TJSONValue): string;
var x : integer;
    obj, obj2 : TJSONObject;
    arr : TJSONArray;
    lsDestructor, lsConstructor, lsJsonToClass : TStringList;
    columnStr, columnTypeStr, childrenClassType, functionJsonToClass : string;
    haveChildrenClass, temClasse, temLista : boolean;
begin
  result := '';
  if (trim(className) = '') then
    exit;

  if (value is TJSONArray) and (TJSONArray(value).Count > 0) then
  begin
    if (TJSONArray(value).Items[0] is TJSONObject) then
      obj := TJSONObject(TJSONArray(value).Items[0]);
  end
  else
    obj := TJSONObject(value);

  if (obj = nil) then
    exit;

  lsConstructor := TStringList.Create;
  lsDestructor := TStringList.Create;
  haveChildrenClass := false;
  temClasse := false;
  temLista := false;
  for x := 0 to obj.Count - 1 do
  begin
    columnStr := obj.Pairs[x].JsonString.Value;
    columnStr := Copy(columnStr, 1, 1).ToUpper + Copy(columnStr, 2, length(columnStr));
    columnTypeStr := ColumnType(obj.Pairs[x]);

    if (columnTypeStr = 'TJSONArray') then
    begin
      columnTypeStr := 'TList<T'+ columnStr +'>';
      haveChildrenClass := true;
      temLista := true;
    end
    else if (columnTypeStr = 'TJSONObject') then
    begin
      columnTypeStr := 'T'+ columnStr;
      haveChildrenClass := true;
      temClasse := true;
    end
    else
      continue;

    lsConstructor.Add(space(2) + columnStr + ' := ' + columnTypeStr +'.Create;');

    if (columnTypeStr.Contains('TList')) then //se for TList
      lsDestructor.Add(space(2) +'while (' + columnStr + '.Count > 0) do' +sLineBreak+
        space(2) + 'begin' +sLineBreak+
        space(4) + ClearMemory(columnStr +'.items[0]') +sLineBreak+
        space(4) + columnStr +'.Delete(0);' +sLineBreak+
        space(2) + 'end;' +sLineBreak+
        space(2) + ClearMemory(columnStr))
    else
      lsDestructor.Add(space(2) + ClearMemory(columnStr));
  end;

  result := '{ '+ className +' }' +sLineBreak+
    sLineBreak+
    'constructor ' + className +'.Create;' +sLineBreak+
    'begin' +sLineBreak+
    lsConstructor.Text +
    'end;' +sLineBreak+
    sLineBreak+
    'destructor ' + className +'.Destroy;' +sLineBreak+
    'begin' +sLineBreak+
    lsDestructor.Text +sLineBreak+
    space(2) +'inherited;' +sLineBreak+
    'end;';

  lsConstructor.Free;
  lsDestructor.Free;

  //monta a rotina de converter um jsonObject em classe
  functionJsonToClass := '';
  lsJsonToClass := TStringList.Create;
  for x := 0 to obj.Count - 1 do
  begin
    childrenClassType := '';
    columnStr := obj.Pairs[x].JsonString.Value;
    columnStr := Copy(columnStr, 1, 1).ToUpper + Copy(columnStr, 2, length(columnStr));
    columnTypeStr := ColumnType(obj.Pairs[x]);

    if (columnTypeStr = 'TJSONArray') then
    begin
      arr := TJSONArray(obj.Pairs[x].JsonValue);

      if (arr.Count > 0) then
      begin
        obj2 := TJSONObject(arr.Items[0]);
        if (obj = nil) then
          exit;

        lsJsonToClass.Add(
          space(2) + 'try' +sLineBreak+
          space(4) + 'value.TryGetValue<TJSONArray>('''+ obj.Pairs[x].JsonString.Value +''', arr);' +sLineBreak+
          space(4) + 'if (arr <> nil) then' +sLineBreak+
          space(6) + 'for x := 0 to arr.count - 1 do' +sLineBreak+
          space(6) + 'begin' +sLineBreak+
          space(8) + 'obj := TJSONObject(arr.items[x]);' +sLineBreak+
          space(8) + 'if (obj = nil) then' +sLineBreak+
          space(10) + 'continue;' +sLineBreak+
          sLineBreak+
          space(8) + 'self.F'+ columnStr +'.add(' +sLineBreak+
          space(10) + 'T'+ columnStr +'.CreateWithJson(obj)' +sLineBreak+
          space(8) + ');' +sLineBreak+
          space(6) + 'end;' +sLineBreak+
          space(2) + 'except' +sLineBreak+
          space(2) + 'end;'
        );
      end;
    end
    else if (columnTypeStr = 'TJSONObject') then
    begin
      lsJsonToClass.Add(
        space(2) + 'try' +sLineBreak+
        space(4) + 'value.TryGetValue<TJSONObject>('''+ obj.Pairs[x].JsonString.Value +''', obj);' +sLineBreak+
        space(4) + 'if (obj <> nil) then' +sLineBreak+
        space(4) + 'begin' +sLineBreak+
        space(6) + ClearMemory('self.F'+ columnStr) +sLineBreak+
        space(6) + 'self.F'+ columnStr +' := T'+ columnStr + '.CreateWithJson(obj);' +sLineBreak+
        space(4) + 'end;' +sLineBreak+
        space(2) + 'except' +sLineBreak+
        space(2) + 'end;'
      );
    end
    else
    begin
      lsJsonToClass.Add(
        space(2) + 'try value.TryGetValue<'+ columnTypeStr +'>('''+ obj.Pairs[x].JsonString.Value +''', self.F'+ columnStr +'); except end;'
      );
    end;
  end;

  result := result +sLineBreak+sLineBreak+
    'constructor '+ className +'.CreateWithJson(const value : TJSonObject);' +sLineBreak;

  if (haveChildrenClass) then
  begin
    if (temClasse) and (temLista) then
      result := result +
        'var arr : TJSONArray;' +sLineBreak+
        space(4) + 'obj : TJSONObject;' +sLineBreak+
        space(4) + 'x : integer;' +sLineBreak+
        'begin' +sLineBreak+
        space(2) +'obj := nil;' +sLineBreak+
        space(2) +'arr := nil;' +sLineBreak
    else if (temClasse) then
      result := result +
        'var obj : TJSONObject;' +sLineBreak+
        'begin' +sLineBreak+
        space(2) +'obj := nil;' +sLineBreak
    else if (temLista) then
      result := result +
        'var arr : TJSONArray;' +sLineBreak+
        space(4) + 'obj : TJSONObject;' +sLineBreak+
        space(4) + 'x : integer;' +sLineBreak+
        'begin' +sLineBreak+
        space(2) +'arr := nil;' +sLineBreak;
  end
  else
    result := result + 'begin' +sLineBreak;

  result := result +
    space(2) +'self.Create;' +sLineBreak+
    space(2) +'if (value = nil) then' +sLineBreak+
    space(4) +'exit;' +sLineBreak+sLineBreak+
    lsJsonToClass.Text +
    'end;';

  lsJsonToClass.Free;

  //CreateWithJsonString
  result := result +sLineBreak+sLineBreak+
    'constructor '+ className +'.CreateWithJsonString(const value : string);' +sLineBreak+
    'var obj : TJSONObject;' +sLineBreak+
    'begin' +sLineBreak+
    space(2) + 'obj := TJSONObject(TJSONObject.ParseJSONValue(value));' +sLineBreak+
    space(2) + 'try' +sLineBreak+
    space(4) + 'self.CreateWithJson(obj);' +sLineBreak+
    space(2) + 'finally' +sLineBreak+
    space(4) + ClearMemory('obj') +sLineBreak+
    space(2) + 'end;' +sLineBreak+
    'end;';

  //monta estrutura dos filhos
  if (haveChildrenClass) then
  begin
    for x := 0 to obj.Count - 1 do
    begin
      childrenClassType := '';
      columnStr := obj.Pairs[x].JsonString.Value;
      columnStr := Copy(columnStr, 1, 1).ToUpper + Copy(columnStr, 2, length(columnStr));
      columnTypeStr := ColumnType(obj.Pairs[x]);

      if (columnTypeStr = 'TJSONArray') then
      begin
        childrenClassType := generateImplementation('T'+ columnStr, TJSONArray(obj.Pairs[x].JsonValue));
      end
      else if (columnTypeStr = 'TJSONObject') then
      begin
        childrenClassType := generateImplementation('T'+ columnStr, TJSONObject(obj.Pairs[x].JsonValue));
      end;

      if (childrenClassType <> '') then
        result := childrenClassType +sLineBreak+sLineBreak+ result;
    end;
  end;
end;

function TJSonToClass.generateType(const className : string; value : TJSONValue) : string;
var x : integer;
    obj, obj2 : TJSONObject;
    arr : TJSONArray;
    columnStr, columnTypeStr, privateTxt, publishedTxt, publicTxt, childrenClassType : string;
    haveChildrenClass : boolean;
begin
  result := '';
  if (value = nil) then
    exit;

  if (value is TJSONArray) and (TJSONArray(value).Count > 0) then
  begin
    if (TJSONArray(value).Items[0] is TJSONObject) then
      obj := TJSONObject(TJSONArray(value).Items[0]);
  end
  else
    obj := TJSONObject(value);

  if (obj = nil) then
    exit;

  result := space(2) + className + ' = class'+ sLineBreak;

  haveChildrenClass := false;
  privateTxt := '';
  publishedTxt := '';
  for x := 0 to obj.Count - 1 do
  begin
    columnStr := obj.Pairs[x].JsonString.Value;
    columnStr := Copy(columnStr, 1, 1).ToUpper + Copy(columnStr, 2, length(columnStr));
    columnTypeStr := ColumnType(obj.Pairs[x]);

    if (columnTypeStr = 'TJSONArray') then
    begin
      columnTypeStr := 'TList<T'+ columnStr +'>';
      haveChildrenClass := true;
    end
    else if (columnTypeStr = 'TJSONObject') then
    begin
      columnTypeStr := 'T'+ columnStr;
      haveChildrenClass := true;
    end;

    if (privateTxt = '') then
      privateTxt := space(4) + '[Coluna('''+ columnStr.ToLower +''')]' +sLineBreak+
        space(4) + 'F'+ columnStr + ': '+ columnTypeStr +';'
    else
      privateTxt := privateTxt +sLineBreak+ space(4) + '[Coluna('''+ columnStr.ToLower +''')]' +sLineBreak+
        space(4) + 'F'+ columnStr + ': '+ columnTypeStr +';';

    if (publishedTxt = '') then
      publishedTxt := space(4) + 'property '+ columnStr +': '+ columnTypeStr +' read F'+ columnStr +
        ' write F'+ columnStr + ';'
    else
      publishedTxt := publishedTxt +sLineBreak+ space(4) + 'property '+ columnStr +': '+ columnTypeStr +' read F'+ columnStr +
        ' write F'+ columnStr + ';';
  end;

  publicTxt := space(4) + 'constructor Create;' +sLineBreak+
    space(4) + 'destructor Destroy; override;' +sLineBreak+sLineBreak+
    space(4) + 'constructor CreateWithJson(const value : TJSonObject);' +sLineBreak+
    space(4) + 'constructor CreateWithJsonString(const value : string);';

  result := result +
    space(2) + 'private' +sLineBreak+ privateTxt +sLineBreak+
    space(2) + 'public' +sLineBreak + publicTxt +sLineBreak+ publishedTxt;

  //monta estrutura dos filhos
  if (haveChildrenClass) then
  begin
    for x := 0 to obj.Count - 1 do
    begin
      childrenClassType := '';
      columnStr := obj.Pairs[x].JsonString.Value;
      columnStr := Copy(columnStr, 1, 1).ToUpper + Copy(columnStr, 2, length(columnStr));
      columnTypeStr := ColumnType(obj.Pairs[x]);

      if (columnTypeStr = 'TJSONArray') then
      begin
        arr := TJSONArray(obj.Pairs[x].JsonValue);
        childrenClassType := generateType('T'+ columnStr, arr);
      end
      else if (columnTypeStr = 'TJSONObject') then
      begin
        obj2 := TJSONObject(obj.Pairs[x].JsonValue);
        childrenClassType := generateType('T'+ columnStr, obj2);
      end;

      if (childrenClassType <> '') then
        result := childrenClassType +sLineBreak+
          space(2) +'end;'+sLineBreak+sLineBreak+
          result;
    end;
  end;
end;

class function TJSonToClass.new(unitName : string) : IJsonToClass;
begin
  result := TJSonToClass.Create(unitName);
end;

function TJSonToClass.setClassRoot(const value: string): IJsonToClass;
begin
  result := self;
  if (value = '') then
    exit;

  FClassRoot := value;
end;

end.
