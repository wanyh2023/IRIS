# 1 HTTP请求简介

创建`%Net.HttpRequest`的实例，以发送各种HTTP请求并接收响应。此对象相当于web浏览器，您可以使用它发出多个请求。它会自动发送正确的cookie，并根据需要设置Referer标头。

要创建HTTP请求，请使用以下常规过程：

1. 创建`%Net.HttpRequest`的实例。

2. 设置此实例的属性以指示要与之通信的web服务器。基本属性如下：

   - *Server*指定web服务器的IP地址或计算机名。默认值为localhost。

     >**注：**
     >不要将http://或https://作为服务器值的一部分。这导致错误#6059：无法打开服务器http://的TCP/IP套接字。

   - *Port*指定要连接的端口。默认值为80。

3. 可以选择设置HTTP请求的其他属性和调用方法，如“指定其他HTTP请求属性”中所述。

4. 然后通过调用`%Net.HttpRequest`实例的`Get()`方法或其他方法发送HTTP请求，如“发送HTTP请求”中所述。

   您可以从实例发出多个请求，这将自动处理cookie和Referer标头。

   >**注：**
   >如果您创建了此HTTP请求用于生产出站适配器（`EnsLib.HTTP.OutboundAdapter`），请改用该适配器的方法发送请求。

5. 如果需要，请使用`%Net.HttpRequest`的相同实例发送其他HTTP请求。默认情况下，InterSystems IRIS保持TCP/IP套接字打开，这样您就可以在不关闭和重新打开套接字的情况下重用该套接字。

   有关更多信息，请参阅“管理套接字重用”。

以下是一个简单的示例：

```java
 set request=##class(%Net.HttpRequest).%New()
 set request.Server="tools.ietf.org"
 set request.Https=1
 set request.SSLConfiguration="TEST"
 set status=request.Get("/html/rfc7158")
```



# 2 提供身份验证

如果目标服务器需要登录凭据，则HTTP请求可以包含提供凭据的HTTP授权标头。以下小节提供了详细信息：

- 使用HTTP 1.0时验证请求
- 使用HTTP 1.1时验证请求
- 直接指定授权标头
- 启用HTTP身份验证的日志记录

如果您使用的是代理服务器，还可以指定代理服务器的登录凭据；为此，请设置`ProxyAuthorization`属性；请参阅“使用代理服务器”。有关详细信息，请参阅`%Net.HttpRequest`的类文档。

## 2.1 使用HTTP 1.0时验证请求

对于HTTP 1.0，要验证HTTP请求，请设置`%Net.HttpRequest`实例的用户名和密码属性。然后，该实例使用基本访问验证（RFC 2617）基于该用户名和密码创建`HTTP Authorization`标头。此`%Net.HttpRequest`发送的任何后续请求都将包含此标头。

> 重要：
> 确保同时使用SSL（请参阅“使用SSL连接”）。在基本身份验证中，凭证以base-64编码的形式发送，因此很容易读取。

## 2.2 使用HTTP 1.1时验证请求

对于HTTP 1.1，要验证HTTP请求，在大多数情况下，只需设置`%Net.HttpRequest`实例的用户名和密码属性。当`%Net.httpRequest`实例收到401 HTTP状态代码和`WWW-Authenticate`标头时，它会尝试使用包含支持的身份验证方案的`Authorization`标头进行响应。使用InterSystems IRIS支持和配置的第一种方案。默认情况下，它按以下顺序考虑这些身份验证方案：

1. Negotiate（SPNEGO和Kerberos，根据RFC 4559，RFC 4178）

2. NTLM（NT LAN Manager身份验证协议）

3. Basic（RFC 2617中描述的基本访问验证）

   > 重要：
   >
   > 如果有可能使用基本身份验证，请确保同时使用SSL（请参阅“使用SSL连接”）。在基本身份验证中，凭证以base-64编码的形式发送，因此很容易读取。

在Windows上，如果未指定用户名属性，InterSystems IRIS可以使用当前登录上下文。具体而言，如果服务器以401状态代码和SPNEGO、Kerberos或NTLM的`WWW-Authenticate`标头进行响应，则InterSystems IRIS使用当前操作系统用户名和密码创建`Authorization`标头。

详细信息与HTTP 1.0的情况不同，如下所示：

- 如果身份验证成功，InterSystems IRIS将实例中更新`%Net.HttpRequest`的`CurrentAuthenticationScheme`属性，以指示其用于最新身份验证的身份验证方案。
- 如果尝试获取方案的身份验证句柄或令牌失败，InterSystems IRIS会将基础错误保存到实例中`%Net.HttpRequest`的`AuthenticationErrors`属性中。此属性的值是**$LIST**，其中每个项都具有格式方案ERROR:message

只有HTTP 1.1支持协商和NTLM，因为这些方案需要多次往返，而HTTP 1.0要求在每个请求/响应对之后关闭连接。

### 2.2.1 变化

如果您知道服务器允许的一个或多个身份验证方案，则可以通过包含所选方案的服务器初始令牌的`Authorization`标头来绕过服务器的初始往返。为此，请在实例中设置`%Net.HttpRequest`的`InitiateAuthentication`属性。对于此属性的值，请指定服务器允许的单个授权方案的名称。使用以下值之一（区分大小写）：

- **Negotiate**
- **NTLM**
- **Basic**

如果要自定义要使用的身份验证方案（或更改其考虑顺序），请在实例中设置`%Net.HttpRequest`的`AuthenticationSchemes`。对于此属性的值，请指定一个逗号分隔的身份验证方案名称列表（使用上一列表中给出的确切值）。

## 2.3 直接指定授权标头

对于HTTP 1.0或HTTP 1.1（如果适用于您的场景），您可以直接指定HTTP Authorization标头。具体来说，您将Authorization属性设置为等于用户代理为您请求的资源所需的身份验证信息。

如果指定Authorization属性，则会忽略Username和Password属性。

## 2.4 启用HTTP身份验证的日志记录

要启用HTTP身份验证的日志记录，请在终端中输入以下内容：

```java
 set $namespace="%SYS"
 kill ^ISCLOG
 set ^%ISCLOG=2
 set ^%ISCLOG("Category","HttpRequest")=5
```

日志条目将写入`^ISCLOG`全局。要将日志写入文件（以便于阅读），请输入以下内容（仍在%SYS命名空间中）：

```java
 do ##class(%OAuth2.Utils).DisplayLog("filename")
```

其中filename是要创建的文件的名称。目录必须已存在。如果文件已存在，则将覆盖该文件。

要停止日志记录，请输入以下内容（仍在%SYS命名空间中）：

```java
 set ^%ISCLOG=0
 set ^%ISCLOG("Category","HttpRequest")=0
```



# 3 指定其他HTTP请求属性

在发送HTTP请求之前（请参阅“发送HTTP请求”），可以指定其属性，如以下部分所述：

- Location属性

- 指定Internet媒体类型和字符编码

- 使用代理服务器

- 使用SSL连接

- HTTPVersion、Timeout、WriteTimeout和FollowRedirect属性

- 指定HTTP请求的默认值

您可以为%Net.HttpRequest的所有属性指定默认值，如最后列出的部分所述。

## 3.1 Location属性

Location属性指定您从web服务器请求的资源。如果设置此属性，那么当调用Get()、Head()、Post()或Put()方法时，可以省略位置参数。

例如，假设您正在向URL发送HTTP请求，http://machine_name/test/index.html

在这种情况下，您将使用以下值：

**%Net.HttpRequest的属性示例**

| Properties | Value               |
| :--------- | :------------------ |
| *Server*   | **machine_name**    |
| *Location* | **test/index.html** |

## 3.2 指定Internet媒体类型和字符编码

您可以使用以下属性指定Internet媒体类型（也称为MIME类型），并在`%Net.HttpRequest`实例中指定字符编码及其响应：

- `ContentType`指定ContentType标头，该标头指定请求主体的Internet媒体类型。默认类型为none。

  可能的值包括application/json、application/pdf、application/postscript、image/jpeg、image/png、multipart/form data、text/html、text/plain、text/xml等。

- 如果内容类型为text（例如text/html或text/xml），`ContentCharset`属性控制请求的任何内容所需的字符集。如果未指定此属性，InterSystems IRIS将使用InterSystems IRIS服务器的默认编码。

  > 注:
  >
  > 如果设置此属性，则必须首先设置ContentType属性。

- `NoDefaultContentCharset`属性控制如果尚未设置ContentCharset特性，是否为文本类型的内容包含显式字符集。默认情况下，此属性为false。

  如果此属性为true，那么如果您有文本类型的内容，并且没有设置ContentCharset属性，则内容类型中不包含字符集；这意味着字符集iso-8859–1用于消息的输出。

- `WriteRawMode`属性影响实体主体（如果包含）。它控制请求主体的编写方式。默认情况下，此属性为false，InterSystems IRIS将主体写入请求标头中指定的编码中。如果此属性为true，InterSystems IRIS将以RAW模式写入正文（不执行字符集的转换）。

- `ReadRawMode`属性控制如何读取响应主体。默认情况下，此属性为false，并且InterSystems IRIS假定主体位于响应标头中指定的字符集中。如果此属性为true，InterSystems IRIS将以RAW模式读取主体（不执行字符集的转换）。

## 3.3 使用代理服务器

您可以通过代理服务器发送HTTP请求。为了进行设置，请指定HTTP请求的以下属性：

- `proxyServer`指定要使用的代理服务器的主机名。如果此属性不为空，则HTTP请求将定向到此计算机。
- `ProxyPort`指定代理服务器上要连接的端口。
- `ProxyAuthorization`指定代理授权标头，如果用户代理必须使用代理进行身份验证，则必须设置该标头。对于该值，请使用用户代理请求的资源所需的身份验证信息。另请参阅“提供登录凭据”
- `ProxyHTTPS`控制HTTP请求是否针对HTTPS页面，而不是普通HTTP页面。如果尚未指定代理服务器，则忽略此属性。此属性将目标系统上的默认端口更改为443，即代理端口。另请参阅“使用SSL连接”
- `ProxyTunnel`指定是否通过代理建立到目标HTTP服务器的隧道。如果为true，则请求使用HTTPCONNECT命令建立隧道。代理服务器的地址取自ProxyServer和ProxyPort属性。如果ProxyHttps为true，那么一旦建立了隧道，InterSystems IRIS就协商SSL连接。在这种情况下，Https属性被忽略，因为隧道建立了与目标系统的直接连接。

有关详细信息，请参阅`%Net.HttpRequest`的类文档。

## 3.4 使用SSL连接

`%Net.HttpRequest`支持SSL连接。要通过SSL发送请求，请执行以下操作：

1. 将`SSLConfiguration`属性设置为要使用的已激活SSL/TLS配置的名称。

   有关创建和管理SSL/TLS配置的信息，请参阅InterSystems TCP Guide。SSL/TLS配置包括一个名为configuration Name的选项，该选项是用于此设置的字符串。

2. 根据您是否使用代理服务器，还可以执行以下操作之一：

   - 如果您没有使用代理服务器，请将Https属性设置为true。

   - 如果您使用的是代理服务器，请将ProxyHTTPS属性设置为true。

     在这种情况下，要使用到代理服务器本身的SSL连接，请将Https属性设置为true。

注意，当您使用到给定服务器的SSL连接时，该服务器上的默认端口假定为443（HTTPS端口）。例如，如果您没有使用代理服务器，并且Https为true，则会将默认Port属性更改为443。

另请参阅“使用代理服务器”

### 3.4.1 服务器标识检查

默认情况下，当`%Net.HttpRequest`的实例连接到SSL/TLS安全web服务器时，它会检查证书服务器名称是否与用于连接到服务器的DNS名称匹配。如果这些名称不匹配，则不允许连接。这种默认行为可防止“中间人”攻击，如RFC 2818；另请参阅RFC 2595。

要禁用此检查，请将`SSLCheckServerIdentity`属性设置为0。

## 3.5 HTTPVersion、Timeout、WriteTimeout和FollowRedirect属性

`%Net.HttpRequest`还提供以下属性：

- `HTTPVersion`指定请求页面时要使用的HTTP版本。默认值为“HTTP/1.1”。您也可以使用“HTTP/1.0”。
- `Timeout`指定等待web服务器响应的时间（秒）。默认值为30秒。
- `WriteTimeout`指定等待web服务器完成写入的时间（以秒为单位）。默认情况下，它将无限期等待。最小可接受值为2秒。
- `FollowRedirect`指定是否自动跟踪来自web服务器的重定向请求（由范围为300–399的HTTP状态代码发出信号）。如果使用GET或HEAD，则默认值为true；否则为假。

## 3.6 指定HTTP请求的默认值

您可以为`%Net.HttpRequest`的所有属性指定默认值。

- 要指定适用于所有命名空间的默认值，请设置全局节点`^%SYS("HttpRequest","propname")`，其中"propname"是属性的名称。

- 要为一个名称空间指定默认值，请转到该名称空间并设置节点`^SYS("HttpRequest","propname")`。

  （^%SYS全局影响整个安装，^SYS全局影响当前命名空间。）

例如，要为所有命名空间指定默认代理服务器，请设置全局节点`^%SYS("HttpRequest","ProxyServer")`。



# 4 设置和获取HTTP标头

您可以设置和获取HTTP标头的值。

`%Net.HttpRequest`的以下每个属性都包含具有相应名称的HTTP标头的值。如果不设置这些属性，则会自动计算这些属性：

- Authorization


- ContentEncoding


- ContentLength （此属性是只读的）


- ContentType （指定Internet媒体类型（MIME类型））


- ContentCharset （指定Content-Type标头的字符集部分。如果设置了该部分，则必须首先设置ContentType属性。）


- Date


- From


- IfModifiedSince


- Pragma


- ProxyAuthorization


- Referer


- UserAgent

`%Net.HttpRequest`提供了可用于设置和获取主HTTP标头的常规方法。这些方法忽略Content-Type和其他实体标头。

- `ReturnHeaders()`

  返回包含此请求中的主要HTTP标头的字符串。

- `OutputHeaders()`

  将主HTTP标头写入当前设备。

- `GetHeader()`

  返回在此请求中设置的任何主HTTP标头的当前值。此方法采用一个参数，即标头的名称（不区分大小写）；这是一个字符串，例如Host或Date。

- `SetHeader()`

  设置标头的值。通常，您可以使用此设置非标准标头；大多数常见的标题都是通过Date等属性设置的。此方法采用两个参数：

  1. 标头的名称（不区分大小写），不带冒号（：）分隔符；这是一个字符串，例如Host或Date
  2. 该标头的值

  不能使用此方法设置实体标头或只读标头（内容长度和连接）。

有关详细信息，请参阅`%Net.HttpRequest`的类文档。



# 5 管理Keep-alive行为

如果重用`%Net.HttpRequest`的同一实例来发送多个HTTP请求，默认情况下，InterSystems IRIS会保持TCP/IP套接字打开，这样InterSystems IRIS就不需要关闭并重新打开它。

如果不想重用TCP/IP套接字，请将SocketTimeout属性设置为0。

`%Net.HttpRequest`的`SocketTimeout`属性指定InterSystems IRIS将重用给定套接字的时间窗口（以秒为单位）。此超时旨在避免使用可能已被防火墙默默关闭的套接字。此属性的默认值为115。您可以将其设置为不同的值。



# 6 处理HTTP请求参数

发送HTTP请求时（请参阅“发送HTTP请求”），可以在*location*参数中包含参数；例如：“/test.html?PARAM=%25VALUE”将PARAM设置为%VALUE。

您还可以使用以下方法控制`%Net.HttpRequest`的实例如何处理参数：

**`InsertParam()`**

	在请求中插入参数。此方法接受两个字符串参数：参数的名称和参数的值。例如：

```java
 do req.InsertParam("arg1","1")
```

可以为给定参数插入多个值。如果这样做，值将收到以1开头的下标。在其他方法中，可以使用这些下标来引用预期值。

**`DeleteParam()`**

	从请求中删除参数。第一个参数是参数的名称。第二个参数是要删除的值的下标；仅当请求包含同一参数的多个值时，才使用此选项。

**`CountParam()`**

	统计与给定参数关联的值的数量。

**`GetParam()`**

	获取请求中给定参数的值。第一个参数是参数的名称。第二个参数是如果请求没有此名称的参数，则返回的默认值；此默认值的初始值为空值。第三个参数是要获取的值的下标；仅当请求包含同一参数的多个值时，才使用此选项。

**`IsParamDefined()`**

	检查是否定义了给定参数。如果参数有值，则此方法返回true。参数与`DeleteParam()`的参数相同。

**`NextParam()`**

	通过`$Order()`对参数名称进行排序后，检索下一个参数的名称（如果有）。

**`ReturnParams()`**

	返回此请求中的参数列表。

有关详细信息，请参阅`%Net.HttpRequest`的类文档。



# 7 包括请求主体

HTTP请求可以包括请求主体或表单数据。要包含请求主体，请执行以下操作：

1. 创建`%GlobalBinaryStream`或子类的实例。将此实例用于HTTP请求的`EntityBody`属性。
2. 使用标准流接口将数据写入此流。例如：

```java
 Do oref.EntityBody.Write("Data into stream")
```

例如，您可以读取一个文件，并将其用作自定义HTTP请求的实体主体：

```java
 set file=##class(%File).%New("G:\customer\catalog.xml")
 set status=file.Open("RS")
 if $$$ISERR(status) do $System.Status.DisplayError(status)
 set hr=##class(%Net.HttpRequest).%New()
 do hr.EntityBody.CopyFrom(file)
 do file.Close()
```

## 7.1 发送分块请求

如果使用HTTP 1.1，则可以以块的形式发送HTTP请求。这包括设置传输编码以指示消息已分块，并使用零大小的块来指示完成。

当服务器返回大量数据并且在请求完全处理之前不知道响应的总大小时，分块编码非常有用。在这种情况下，通常需要缓冲整个消息，直到可以计算内容长度（`%Net.HttpRequest`会自动计算）。

要发送分块请求，请执行以下操作：

1. 创建`%Net.ChunkedWriter`的子类，该子类是一个抽象流类，它定义了一个以块形式写入数据的接口。

   在这个子类中，实现`OutputStream()`方法。

2. 在%Net.HttpRequest实例中，创建%Net.ChunkedWriter子类实例，并用要发送的请求数据填充该实例。

3. 将实例中`%Net.HttpRequest`的`EntityBody`属性设置为等于`%Net.ChunkedWriter`的实例。

   发送HTTP请求时（请参阅“发送HTTP请求”），它会调用`EntityBody`属性的`OutputStream()`方法。

在`%Net.ChunkedWriter`的子类中，`OutputStream()`方法应检查流数据，决定是否将其分块以及如何分块，并调用类的继承方法来写入输出。

以下方法可用：

**`WriteSingleChunk()`**

	接受字符串参数并将字符串作为非分块输出写入。

**`WriteFirstChunk()`**

	接受字符串参数。写入适当的传输编码标题以指示分块消息，然后将字符串作为第一个分块写入。

**`WriteChunk()`**

	接受字符串参数并将字符串作为块写入。

**`WriteLastChunk()`**

	接受字符串参数并将字符串作为块写入，后跟一个零长度的块以标记结尾。

如果非空，则`TranslateTable`属性指定用于在编写字符串时转换每个字符串的转换表。前面的所有方法都检查此属性。



# 8 发送表单数据

HTTP请求可以包括请求主体或表单数据。要包含表单数据，请使用以下方法：

**`InsertFormData()`**

	在请求中插入表单数据。此方法接受两个字符串参数：表单项的名称和关联值。可以为给定的表单项插入多个值。如果这样做，值将收到以1开头的下标。在其他方法中，可以使用这些下标来引用预期值

**`DeleteFormData()`**

	从请求中删除表单数据。第一个参数是表单项的名称。第二个参数是要删除的值的下标；仅当请求包含同一表单项的多个值时，才使用此选项。

**`CountFormData()`**

	统计请求中与给定名称关联的值的数量。

**`IsFormDataDefined()`**

	检查是否定义了给定名称

**`NextFormData()`**

	通过`$Order()`对名称进行排序后，检索下一个表单项的名称（如果有）。

有关这些方法的详细信息，请参阅`%Net.HttpRequest`的类文档。

## 8.1 示例1

插入表单数据后，通常调用`Post()`方法。例如：

```java
    Do httprequest.InsertFormData("element","value")
    Do httprequest.Post("/cgi-bin/script.CGI")
```

## 8.2 示例2

例如：

```java
    Set httprequest=##class(%Net.HttpRequest).%New()
    set httprequest.SSLConfiguration="MySSLConfiguration"
    set httprequest.Https=1
    set httprequest.Server="myserver.com"
    set httprequest.Port=443
    Do httprequest.InsertFormData("portalid","2000000")
    set tSc = httprequest.Post("/url-path/")
    Quit httprequest.HttpResponse
```



# 9 插入、列出和删除Cookie

`%Net.HttpRequest`自动管理从服务器发送的cookie；如果服务器发送cookie，则`%Net.HttpRequest`的实例将在下次请求时返回此cookie。（要使此机制工作，您需要重用`%Net.HttpRequest`的相同实例。）

使用以下方法管理`%Net.HttpRequest`实例中的cookie：

**`InsertCookie()`**

	在请求中插入cookie。指定以下参数：

1. cookie的名称。
2. cookie的值。
3. 应存储cookie的路径。
4. 从中下载cookie的计算机的名称。
5. cookie过期的日期和时间。

**`GetFullCookieList()`**

	返回cookie的数量并返回（通过引用）cookie数组。

**`DeleteCookie()`**

	从请求中删除cookie。

有关这些方法的详细信息，请参阅`%Net.HttpRequest`的类文档。



# 10 发送HTTP请求

创建HTTP请求后，请使用以下方法之一发送它：

**`Delete()`**

```java
method Delete(location As %String = "", 
              test As %Integer = 0, 
              reset As %Boolean = 1) as %Status
```

发出HTTP DELETE请求。

**`Get()`**

```java
method Get(location As %String = "", 
           test As %Integer = 0, 
           reset As %Boolean = 1) as %Status
```

发出HTTP GET请求。此方法使web服务器返回请求的页面。

**`Head()`**

```java
method Head(location As %String, 
            test As %Integer = 0, 
            reset As %Boolean = 1) as %Status
```

发出HTTP HEAD请求。此方法使web服务器只返回响应的头，而不返回正文。

**`Patch()`**

```java
method Patch(location As %String = "", 
             test As %Integer = 0, 
             reset As %Boolean = 1) as %Status
```

发出HTTP PATCH请求。使用此方法可以对现有资源进行部分更改。

**`Post()`**

```java
method Post(location As %String = "", 
            test As %Integer = 0, 
            reset As %Boolean = 1) as %Status
```

发出HTTP POST请求。使用此方法可将数据（如表单结果）发送到web服务器，或上载文件。有关示例，请参阅“发送表单数据”

**`Put()`**

```java
method Put(location As %String = "", 
           test As %Integer = 0, 
           reset As %Boolean = 1) as %Status
```

发出HTTP PUT请求。使用此方法将数据上载到web服务器。PUT请求不常见。

**`Send()`**

```java
method Send(type As %String, 
            location As %String, 
            test As %Integer = 0, 
            reset As %Boolean = 1) as %Status
```

向服务器发送指定类型的HTTP请求。此方法通常由其他方法调用，但如果您想使用不同的HTTP谓词，则提供此方法。这里的类型是一个字符串，它指定一个HTTP动词，例如“POST”。

在所有情况下：

- 每个方法都返回一个状态，您应该检查该状态。

- 如果方法正确完成，则此请求的响应将位于HttpResponse属性中。

- location参数是要请求的URL，例如：“/test.html”。

- location参数可以包含参数，这些参数假定已经进行了URL转义，例如：“/test.html?PARAM=%25VALUE”将PARAM设置为%VALUE。

- 使用测试参数检查是否发送了预期发送的内容：

  - 如果测试为1，则该方法将只输出它将发送到web服务器的内容到当前设备，而不是连接到远程计算机。
  - 如果测试为2，那么它将在发出HTTP请求后向当前设备输出响应。

- 每个方法在从服务器读取响应后都会自动调用Reset()方法，除非test=1或Reset=0。

  Reset()方法在实例重置%Net.HttpRequest，以便它可以发出另一个请求。这比关闭此对象并创建新实例快得多。这也会将Location标头的值移动到Refer标头。

例如：

```java
 Set httprequest=##class(%Net.HttpRequest).%New()
 Set httprequest.Server="www.intersystems.com"
 Do httprequest.Get("/")
```

有关其他示例，请参阅`%Net.HttpRequest`的类文档。



# 11 创建和发送多部分POST请求

要创建和发送多部分POST请求，请在使用`%Net.MIMEPart`类，这将在本书后面更详细地讨论。以下示例发送包含两部分的POST请求。第一部分包括文件二进制数据，第二部分包括文件名。

```java
ClassMethod CorrectWriteMIMEMessage3(header As %String) 
{
     // Create root MIMEPart
     Set RootMIMEPart=##class(%Net.MIMEPart).%New()

     //Create binary subpart and insert file data
     Set BinaryMIMEPart=##class(%Net.MIMEPart).%New()
     Set contentdisp="form-data; name="_$CHAR(34)_"file"_$CHAR(34)_"; filename="
                     _$CHAR(34)_"task4059.txt"_$CHAR(34)
     Do BinaryMIMEPart.SetHeader("Content-Disposition",contentdisp)

     Set stream=##class(%FileBinaryStream).%New()
     Set stream.Filename="/home/tabaiba/prueba.txt"
     Do stream.LinkToFile("/home/tabaiba/prueba.txt")

     Set BinaryMIMEPart.Body=stream
     Do BinaryMIMEPart.SetHeader("Content-Type","text/plain")

    // Create text subpart
    Set TextMIMEPart=##class(%Net.MIMEPart).%New()
    Set TextMIMEPart.Body=##class(%GlobalCharacterStream).%New()
    Do TextMIMEPart.Body.Write("/home/tabaiba/prueba.txt")

    // specify some headers
    Set TextMIMEPart.ContentType="text/plain"
    Set TextMIMEPart.ContentCharset="us-ascii"
    Do TextMIMEPart.SetHeader("Custom-header",header)

    // Insert both subparts into the root part
    Do RootMIMEPart.Parts.Insert(BinaryMIMEPart)
    Do RootMIMEPart.Parts.Insert(TextMIMEPart)

    // create MIME writer; write root MIME message
    Set writer=##class(%Net.MIMEWriter).%New()

    // Prepare outputting to the HttpRequestStream
    Set SentHttpRequest=##class(%Net.HttpRequest).%New()
    Set status=writer.OutputToStream(SentHttpRequest.EntityBody)
    if $$$ISERR(status) {do $SYSTEM.Status.DisplayError(status) Quit}

    // Now write down the content
    Set status=writer.WriteMIMEBody(RootMIMEPart)
    if $$$ISERR(status) {do $SYSTEM.Status.DisplayError(status) Quit}

    Set SentHttpRequest.Server="congrio"
    Set SentHttpRequest.Port = 8080

    Set ContentType= "multipart/form-data; boundary="_RootMIMEPart.Boundary
    Set SentHttpRequest.ContentType=ContentType

    set url="alfresco/service/sample/upload.json?"
            _"alf_ticket=TICKET_caee62bf36f0ea5bd51194fce161f99092b75f62"

    set status=SentHttpRequest.Post(url,0) 
    if $$$ISERR(status) {do $SYSTEM.Status.DisplayError(status) Quit}
}
```



# 12 访问HTTP响应

发送HTTP请求后，将更新请求的HttpResponse属性。此属性是`%Net.HttpResponse`的实例。本节介绍如何使用响应对象。它包括以下主题：

- 访问响应数据
- 按名称获取HTTP标头
- 访问有关响应的其他信息

有关详细信息，请参阅`%Net.HttpRequest`的类文档。

## 12.1 访问响应数据

HTTP响应的主体包含在响应的Data属性中。此属性包含流对象（特别是`%GlobalBinaryStream`）。要使用此流，请使用标准流方法：`Write()`、`WriteLine()`、`Read()`、`ReadLine()`，`Rewind()`，`MoveToEnd()`和`Clear()`。也可以使用流的Size属性。

请求的`ReadRawMode`属性控制如何读取响应主体。

- 默认情况下，此属性为false，并且InterSystems IRIS假定主体位于响应的HTTP标头中指定的字符集中（并相应地转换字符集）。
- 如果此属性为true，InterSystems IRIS将以RAW模式读取主体（不执行字符集的转换）。

您还可以使用`OutputToDevice()`方法，该方法将完整响应写入当前设备。标头的顺序与web服务器生成的顺序不同。

下面是一个简单的示例，我们将响应流复制到一个文件中并保存它：

```java
 set request=##class(%Net.HttpRequest).%New()
 set request.Server="tools.ietf.org"
 set request.Https=1
 set request.SSLConfiguration="TEST"
 set status=request.Get("/html/rfc7158")
 if $$$ISERR(status) {
         do $system.OBJ.DisplayError()
 } else {
         set response=request.HttpResponse
 }
 
 Set file=##class(%FileCharacterStream).%New()
 set file.Filename="c:/temp/rfc7158.html"
 set status=file.CopyFrom(response.Data)
 if $$$ISERR(status) {
         do $system.OBJ.DisplayError()
 }
 do file.%Close()
```

## 12.2 按名称获取HTTP标头

`%Net.HttpResponse`将其HTTP标头存储在InterSystems IRIS多维数组中。要访问标头，请使用以下方法：

**`GetHeader()`**

	返回给定标头的值。

**`GetNextHeader()`**

	返回给定标头之后的下一个标头的名称。

这些方法中的每一个都有一个参数，一个字符串是HTTP头的名称。

您还可以使用`OutputHeaders()`方法，该方法将HTTP头写入当前设备（尽管它们的生成顺序不同）。

## 12.3 访问有关响应的其他信息

`%Net.HttpResponse`提供了存储HTTP响应其他特定部分的属性：

- StatusLine存储HTTP状态行，这是响应的第一行。
- StatusCode存储HTTP状态代码。
- ReasonPhrase存储与StatusCode相对应的人类可读原因。
- ContentInfo存储有关响应主体的其他信息。
- ContentType存储Content-Type:header。
- HttpVersion表示发送响应的web服务器支持的HTTP版本。

# 附：发送HTTP请求示例

**notes.HttpRequest**

```java
Class notes.HttpRequest Extends %RegisteredObject
{

/// Amap WebApi Key
Parameter AMAPAPIKEY = "6225218d56b310eccc2ac4b4d280dd39";

/// Sending HTTP Request
ClassMethod SendHttpRequest()
{
	/* 创建%Net.HttpRequest的实例，设置实例属性 */
    s request = ##class(%Net.HttpRequest).%New()
	s request.Server = "restapi.amap.com" //IP
	s request.Port = "80" //端口
	s request.Location = "/v3/weather/weatherInfo" //地址
	s request.Timeout = 3 //等待超时
	
	#; /* 发送HTTP GET请求 */
	#; d request.InsertParam("key", ..#AMAPAPIKEY) //插入参数
	#; d request.InsertParam("city", "340124")
    #; d request.InsertParam("extensions", "all")
	#; s status = request.Get()

	/* 发送HTTP POST请求 */
	d request.InsertFormData("key",..#AMAPAPIKEY) //发送表单
	d request.InsertFormData("city","340124")
	d request.InsertFormData("extensions", "all")
	s status = request.Post()

	/* 接收HTTP响应 */
	if $$$ISERR(status){
		do $system.OBJ.DisplayError()
	}else{
		s response = request.HttpResponse
		s statusCode = response.StatusCode
		s data = response.Data
		s dataObj = {}.%FromJSON(data)
		s forecasts = dataObj.forecasts
		s itr = forecasts.%GetIterator()
		while itr.%GetNext(.key, .val){
			s province = val.province
			s city = val.city
            s reporttime = val.reporttime
            w province_city_" "_reporttime_" 播报：",!
            s casts = val.casts
            s itr = casts.%GetIterator()
            while itr.%GetNext(.key, .val){
			    s date = val.date
			    s week = $CASE(val.week, 1:"星期一", 2:"星期二", 3:"星期三", 4:"星期四", 5:"星期五", 6:"星期六", 7:"星期日")
                s dayweather = val.dayweather
                s nightweather = val.nightweather
                s daytemp = val.daytemp
                s nighttemp = val.nighttemp
                s daywind = val.daywind
                s nightwind = val.nightwind
                s daypower = val.daypower
                s nightpower = val.nightpower
			    w date_" "_week_"：白天，"_dayweather_" "_daytemp_"℃ ，"_daywind_"风"_daypower_"级；"_"夜晚，"_nightweather_" "_nighttemp_"℃ ，"_nightwind_"风"_nightpower_"级。",!
            }
		}
	}

	/* Others */
	#; s request.Https=1 //https连接
	#; s request.Port=443
	#; s request.SSLConfiguration="MySSLConfiguration"

	#; s request.Username="10695144-4GA075FF" //认证方式1
	#; s request.Password="welcome1"
	#; d request.SetHeader("Authorization",token) //认证方式2  //设置标头
		
	#; d request.EntityBody.SetAttribute("CONTENT-TYPE","application/json")  //请求主体
	#; s jsonStream = ##class(%Stream.GlobalCharacter).%New()
	#; d jsonObj.%ToJSON(jsonStream) 
	#; d request.EntityBody.CopyFrom(jsonStream)
}

}

```