# 1 JSON介绍

InterSystems ObjectScript语法包括对JSON的集成支持[(https://json.org/)](https://json.org/)。一组快速、简单、强大的功能使您可以像处理对象或表一样轻松地处理JSON数据结构：

- 使用JSON的ObjectScript语法，您可以使用标准的ObjectScript赋值语句而不是方法调用来在运行时创建和更改动态实体。对象属性和数组元素的值可以指定为JSON字符串文字或ObjectScript动态表达式。
- 两个类，`%Library.DynamicObject`和`%Library.DynamicArray`，为封装和使用标准JSON数据结构提供了一种简单、高效的方法。这些类的实例称为动态实体。
- 动态实体包含JSON序列化（动态实体和规范JSON格式之间的转换）、迭代、数据类型、创建/读取/更新/删除操作以及其他有用功能的方法。



## 1.1 运行中的JSON特性

以下是ObjectScript中可用的JSON功能的一些示例：

- **在运行时创建和操作动态实体**

  您可以创建动态实体并在运行时为其定义任意模式：

  ```java
     set dynObject1 = ##class(%DynamicObject).%New()
     set dynObject1.SomeNumber = 42
     set dynObject1.SomeString = "a string"
     set dynObject1.SomeArray = ##class(%DynamicArray).%New()
     set dynObject1.SomeArray."0" = "an array element"
     set dynObject1.SomeArray."1" = 123
  ```

- **使用JSON构造函数创建动态实体**

  您还可以通过指定JSON字符串来创建动态实体。JSON构造函数`{}`和`[]`可以用来代替`%New()`构造函数。例如，可以使用`set x=[]`而不是 `set x=##class(%DynamicArray).%New()` 创建动态数组。与`%New()`不同，JSON构造函数也可以采用指定属性或元素的JSON文本字符串。这意味着您可以使用以下简单的赋值语句创建与上一示例中dynObject1相同的对象：

  ```java
     set dynObject2 = {"SomeNumber":42,"SomeString":"a string"}
     set dynObject2.SomeArray = ["an array element",123]
  ```

  此示例为每个构造函数使用一个语句，但数组构造函数也可以很容易地嵌套在对象构造函数中。

  为了证明`dynObject1`和`dynObject2`是相同的，我们可以将它们显示为``%ToJSON()``方法返回的序列化JSON字符串：

  ```java
     write "object 1: "_dynObject1.%ToJSON(),!,"object 2: "_dynObject2.%ToJSON()
  
  object 1: {"SomeNumber":42,"SomeString":"a string","SomeArray":["an array element",123]}
  object 2: {"SomeNumber":42,"SomeString":"a string","SomeArray":["an array element",123]}
  ```

- **使用动态表达式定义值**

  构造函数`{}`和`[]`中包含的文本必须使用有效的JSON语法，只有一个例外。对于元素或属性的值，可以使用括号中的表达式，而不是JSON文本。此ObjectScript动态表达式（相当于set语句的右侧）将在运行时求值并转换为有效的JSON值。本示例中的动态表达式包括对`$ZDATE`函数的调用：

  ```java
     set dynObj = { "Date":($ZD($H,3)) }
  ```

  当我们检索`dynObj.Date`，使用表达式值：

  ```java
     write "Value of dynamic expression is: "_dynObject.Date
  
  Value of dynamic expression is: 2016-07-27
  ```

  （有关这些主题的详细讨论，请参阅“动态表达式和点语法”）。

- **在动态实体和规范JSON字符串之间转换**

  动态实体具有序列化方法，允许它们转换为JSON字符串或从JSON字符串转换。在下面的示例中，使用一个文本构造函数创建一个动态对象，并调用该对象的`%ToJSON()`方法将其序列化为`myJSONstring`：

  ```java
     set myJSONstring = {"aNumber":(21*2),"aDate":($ZD($H,3)),"anArray":["string",123]}.%ToJSON()
  
  ```

  这个序列化的JSON对象可以像任何其他字符串一样存储和检索。类方法`%FromJSON()`和`%FromJSONFile()`可以从任何源获取有效的JSON字符串，并将其转换为动态对象。以下代码将`myJSONstring`反序列化为动态对象`myObject`，并使用`%ToJSON()`显示它：

  ```java
     set myObject = ##class(%DynamicAbstractObject).%FromJSON(myJSONstring)
     write myObject.%ToJSON()
  
  {"aNumber":42,"aDate":"2016-08-29","anArray":["string",123]}
  ```

- **链动态实体方法**

  某些动态实体方法可以链接。本例创建了一个包含两个元素的动态数组，然后使用`%Push()`方法将三个元素添加到数组的末尾。对`%ToJSON()`的最后一个链式调用将显示序列化字符串：

  ```java
     set dynArray = ["a","b"]
     write dynArray.%Push(12).%Push({"a":1,"b":2}).%Push("final").%ToJSON()
  
  ["a","b",12,{"a":1,"b":2},"final"]
  ```

  （有关可链接方法的更多信息，请参阅“方法链接”）。

- **迭代和数据类型发现**

  动态实体方法也用于迭代和数据类型发现等目的。本例创建了两个JSON字符串，将其中一个字符串反序列化为`dynEntity`（任何一个都可以），然后为`dynEntity`实体获取迭代器：

  ```java
     set arrayStr = [12,"some string",[1,2]].%ToJSON()
     set objectStr = {"a":12,"b":"some string","c":{"x":1,"y":2}}.%ToJSON()
     set dynEntity = {}.%FromJSON(objectStr)
     set itr = dynEntity.%GetIterator()
  
  ```

  对于while循环的每次迭代，`%GetNext()`将返回key中的属性名或数组索引以及val中的成员值。`%GetTypeOf()`的返回值是一个字符串，指示值的数据类型：

  ```java
     while itr.%GetNext(.key,.val) {write !,key_": "_"/"_val_"/, type: "_dynEntity.%GetTypeOf(key)}
  
  a: /12/, type: number
  b: /some string/, type: string
  c: /1@%Library.DynamicObject/, type: object
  ```

  （有关这些和相关方法的更多信息，请参阅“迭代和稀疏数组”和“使用数据类型”）。



## 1.2 动态实体方法概述

动态实体方法可分为以下类别：

- 创建、读取、更新、删除

  `%Set()`可以更改现有动态实体成员（属性或元素）的值，也可以创建新成员并为其赋值。`%Remove()`删除现有成员。`%Get()`检索成员的值。有关详细信息，请参见“创建和修改动态实体”。

- 迭代和稀疏阵列

  `%GetIterator()`返回一个迭代器，其中包含指向动态实体每个成员的指针。`%GetNext()`返回迭代器标识的成员的键和值，并将光标前进到下一个成员。`%Size()`返回成员数（包括稀疏数组中未分配的元素）。`%IsDefined()`测试成员是否具有赋值。有关详细信息，请参阅“迭代和稀疏阵列”。

- 堆栈函数

  `%Push()`将新元素添加到动态数组的末尾。`%Pop()`删除数组的最后一个元素并返回其值。这些方法不适用于动态对象，因为对象属性不是以可预测的顺序存储的。有关详细信息，请参阅“将`%Push`和`%Pop`用于动态阵列”。

- JSON序列化和反序列化

  `%FromJSON()`转换JSON字符串，`%FromJSONFile()`将存储在文件中的JSON字符串转换为动态实体。`%ToJSON()`将动态实体序列化为规范JSON字符串。有关详细信息，请参阅“将动态实体转换为JSON和从JSON转换为JSON”。

- 数据类型信息

  `%GetTypeOf()`返回一个字符串，指示指定成员值的数据类型。`%Set()`和`%Push()`提供了可选的第三个参数，用于显式指定值的数据类型。有关详细信息，请参阅“使用数据类型”。

请参阅“动态实体方法快速参考”，了解每种方法的描述和更多信息的链接。



# 2 创建和修改动态实体

本章提供有关动态实体如何工作的基本信息。讨论了以下主题：

- 使用JSON简单构造函数
- 使用动态表达式和点语法
- 使用`%Set()`、`%Get()`和`%Remove()`
- 方法链
- 错误处理
- 将动态实体和JSON互转
  - 将大型动态实体序列化为流



## 2.1 使用JSON简单构造函数

动态实体是 `%DynamicObject` 或 `%DynamicArray` 的实例，旨在将JSON数据操作无缝集成到ObjectScript应用程序中。尽管您可以使用标准的 `%New()` 方法创建这些类的实例，但动态实体支持一组更灵活和直观的构造函数。JSON简单构造函数允许您通过将JSON字符串直接分配给变量来创建动态实体。例如，以下代码创建 `%DynamicObject` ， `%DynamicArray` 的空实例：

```java
   set dynamicObject = {}
   set dynamicArray = []
   write dynamicObject,!,dynamicArray

3@%Library.DynamicObject
1@%Library.DynamicArray
```

与 `%New()` 构造函数不同，简单构造函数 `{}` 和 `[]` 可以接受JSON格式的字符串作为参数。例如，以下代码使用名为prop1的属性创建动态对象：

```java
   set dynamicObject = {"prop1":"a string value"}
   write dynamicObject.prop1

a string value
```

事实上，JSON简单构造函数 `{}` 和 `[]` 可以用于指定任何有效的JSON数组或对象结构。简单地说，任何有效的JSON文本字符串也是有效的ObjectScript表达式，其计算结果为动态实体。

*注：*

*必须始终引用JSON属性名称*

​		*JSON语言规范（请参见https://json.org/）是Javascript对象表示法的一个子集，并在某些领域实施更严格的规则。一个重要的区别是，JSON规范要求所有属性名称都用双引号括起来。另一方面，Javascript语法在许多情况下允许使用未加引号的名称。*

动态实体存储JSON字符串中每个对象属性或数组元素的精确表示。任何动态实体都可以使用 `%ToJSON()` 方法将存储的数据作为JSON字符串返回。在转换为文字字符串或从文字字符串转换时，数据不会丢失或损坏。下面的示例创建一个动态数组，然后调用 `%ToJSON()` 来构造并返回表示存储数据的新JSON字符串：

```java
   set dynamicArray = [[1,2,3],{"A":33,"a":"lower case"},1.23456789012345678901234,true,false,null,0,1,""]
   write dynamicArray.%ToJSON()

[[1,2,3],{"A":33,"a":"lower case"},1.23456789012345678901234,true,false,null,0,1,""]
```

此动态数组存储并返回了几个有效值：

- 前两个元素是嵌套数组和嵌套对象。在JSON语法中，数组和对象结构可以嵌套到任何深度。
- 属性名称区分大小写。嵌套对象有两个不同的属性，分别名为“A”和“a”。
- 第三个值是非常高精度的十进制数。如果将该值存储为标准浮点数，则该值将向下舍入，但动态数组保留了原始值的精确表示。
- 最后六个元素包含JSON数据类型值`true`、`false`和`null`，以及相应的ObjectScript值`0`、`1`和`""`。同样，动态实体保留每个值的精确表示。



## 2.2 使用动态表达式和点语法

在JSON中存储值的方式与在ObjectScript中表达值的方式之间存在显著差异。如果每次需要使用ObjectScript值时都必须将其转换为JSON语法或将其转换成JSON语法，则JSON数据存储将非常有用，因此动态实体的设计目的是使转换过程透明。您可以始终存储和检索ObjectScript值，而不必担心它在JSON语法中的表示。

文本JSON构造函数也不例外。到目前为止，我们的所有示例都完全采用JSON语法，但文字构造函数也可以接受动态表达式中定义的值，这些表达式只是用括号括起来的ObjectScript表达式。

例如，以下动态数组构造函数存储两个Unicode字符。在运行时，文本构造函数计算每个元素并存储计算值。第一个元素是用JSON语法定义的，第二个元素是ObjectScript函数调用，但生成的存储值是相同的：

```java
   write ["\u00E9",($CHAR(233))].%ToJSON()

["é","é"]
```

您可以将ObjectScript表达式视为set语句右侧的代码。任何求值为值而不是对象引用的ObjectScript表达式都可以序列化为JSON文本字符串。以下示例在对象属性`obj.LIST`中存储一个`$LIST`值（它是一个分隔字符串，而不是一个对象）。然后创建数组并将`obj.LIST`的每个列表项提取到一个单独的元素中：

```java
   set obj = {"list":($LISTFROMSTRING("Deborah Noah Martha Bowie"," "))}
   set array = [($LIST(obj.list,1)),($LIST(obj.list,2)),($LIST(obj.list,3)),($LIST(obj.list,4))]
   write obj.%ToJSON(),!,array.%ToJSON()

{"list":"\t\u0001Deborah\u0006\u0001Noah\b\u0001Martha\u0007\u0001Bowie"}
["Deborah","Noah","Martha","Bowie"]
```

您不能使用动态表达式定义属性名（尽管有一些方法可以通过编程方式定义属性名。有关详细信息，请参阅“使用`%Set()`、`%Get()`和`%Remove()`”）。

当然，文字构造函数并不是操作对象属性和数组元素的唯一方法。例如，以下代码创建了一个空的动态对象，并使用标准的对象点语法来定义内容：

```java
   set dynArray = []
   set dynArray."0" = "02"_"33"
   set dynArray."1" = {}
   set dynArray."1".foo = $CHAR(dynArray."0")
   write dynArray.%ToJSON()

[233,{"foo":"é"}]
```

在本例中，文字构造函数仅用于创建空的动态实体。赋值语句遵循几个简单的规则：

- 指定的值是标准的ObjectScript表达式。（在本例中，“02”_“33”是一个ObjectScript字符串表达式，计算结果为整数233）。
- 数组元素由数组索引编号寻址，索引编号必须是用双引号括起来的数字文本。动态数组是从零开始的。
- 对象属性由属性名称寻址。尽管属性名是字符串，但如果属性名是有效的类成员名，则双引号是可选的。
- 如果指定的实体成员尚不存在，则将在为其分配值时创建它。

如前所述，值始终以ObjectScript格式存储和检索，而不管它们如何以JSON语法表示。下面的示例演示了使用点语法时应注意的其他一些事实。

**（1）使用点语法创建动态对象属性：**

​		本例使用文本构造函数和点语法创建动态对象 `dynObj` ，其中包含名为A、a和C引号的属性。在文本字符串中，必须引用所有属性名称。在set语句和write语句中，属性名A或a不需要引号，但必须用于C引号：

```java
   set dynObj = {"a":"stuff"}
   set dynObj."C quote" = " ""C quote"" contains a space "
   set dynObj.a = " lower case ""a"" "
   set dynObj.A = " upper case ""A"" "
   write !,dynObj.%ToJSON()

{"a":" lower case \"a\" ","C quote":" \"C quote\" contains a space ","A":" upper case \"A\" "}
```

​		动态对象是无序列表，因此值不一定按创建顺序存储。请参阅“使用%GetNext()在动态实体上迭代”，以了解演示这一点的示例。

**（2）使用点语法创建动态数组元素：**

​		动态数组是从零开始的。此示例在定义元素2之前为数组元素3赋值。元素不必按顺序定义，元素2可能未定义。有关详细信息，请参阅“了解稀疏阵列和未分配值”。

```java
   set dynArray = [true,false]
   set dynArray."3" = "three"
   set dynArray."2" = 0
   write dynArray.%ToJSON()

[true,false,0,"three"]
```

​		尽管前两个元素被定义并存储为JSON布尔值`true`和`false`，但它们被返回为整数`1`和`0`，这是等效的ObjectScript布尔值：

```java
   write "0=/"_dynArray."0"_"/, 1=/"_dynArray."1"_"/, 2=/"_dynArray."2"_"/, 3=/"_dynArray."3"_"/"

0=/1/, 1=/0/, 2=/0/, 3=/three/
```

​		由于存储的值始终以ObjectScript格式返回，JSON `true`、`false`和`null`将作为ObjectScript `0`、1和`""`（空字符串）返回。但是，原始JSON值保留在动态实体中，如果需要可以恢复。有关标识存储值的原始数据类型的信息，请参阅“使用数据类型”。

*注：点语法不应与非常长的属性名称一起使用。*

​		*尽管动态对象属性可以具有任意长度的名称，但ObjectScript不能使用超过180个字符的属性名称。如果动态对象属性名称超过此限制，则尝试在点语法中使用该名称将导致误导性的<property DOS NOT EXIST>错误，即使该属性存在且名称有效。可以使用%Set()和%Ge()方法来避免此错误，它们接受任意长度的属性名。*



## 2.3 使用`%Set()`、`%Get()`和`%Remove()`

虽然文字构造函数和点语法可以用于创建动态实体成员和操作值，但它们并不适合所有用途。动态实体提供 `%Set()` 、 `%Get()` 和 `%Remove()` 方法，以实现对创建、读取、更新和删除操作的完全编程控制。

这些方法最重要的优点之一是成员标识符（属性名和数组索引号）不必是文本。可以使用ObjectScript变量和表达式来指定值和标识符。

**（1）使用 `%Set()` 、 `%Get()` 和 `%Remove()` 以编程方式指定值和标识符：**

​		下面的示例使用文本构造函数 `{}` 创建一个对象，并调用新对象的 `%Set()` 方法来添加一系列名为propn的值为100+n的属性。名称和值都由ObjectScript表达式定义：

```java
   set dynObj = {}
   for i=1:1:5 { do dynObj.%Set("prop"_i,100+i) }
   write dynObj.%ToJSON()

{"prop1":101,"prop2":102,"prop3":103,"prop4":104,"prop5":105}
```

​		相同的变量可以与 `%Get()` 一起使用以检索属性值：

```java
   for i=1:1:5 { write dynObj.%Get("prop"_i)_" " }

101 102 103 104 105
```

​		`%Remove()` 方法从动态实体中删除指定的成员并返回值。此示例删除五个属性中的三个，并将返回值连接到字符串removedValues。write语句显示已删除值的字符串和dynObj的当前内容：

```java
   set removedValues = ""
   for i=2:1:4 { set removedValues = removedValues_dynObj.%Remove("prop"_i)_" " }
   write "Removed values: "_removedValues,!,"Remaining properties: "_dynObj.%ToJSON()

Removed values: 102 103 104
Remaining properties: {"prop1":101,"prop5":105}
```

*注：*

*尽管在这些简单的示例中使用了for循环，但正常的迭代方法应该是 `%GetNext()` （稍后在“使用%GetNext()在动态实体上迭代”中描述）。*

`%Get()` 和 `%Remove()` 都返回指定成员的ObjectScript值，但返回嵌入动态实体的方式有一个重要的区别：

-  `%Get()` 通过引用返回值。返回值是对属性或元素的OREF（对象引用），它又包含对嵌入实体的引用。
- `%Remove()` 销毁指定的属性或元素（使成员OREF无效），但返回一个直接指向先前嵌入实体的有效OREF。

**（2）使用`%Get()`和`%Remove()`检索嵌套的动态实体：**

​		在以下示例中，属性 `dynObj.address` 的值是一个动态对象。`%Get()` 语句在变量addrPointer中存储对属性（而不是属性值）的引用。此时，addrPointer可用于访问嵌入实体地址的道路属性：

```java
   set dynObj = {"name":"greg", "address":{"road":"Old Road"}}
   set addrPointer = dynObj.%Get("address")
   set dynObj.address.road = "New Road"
   write "Value of "_addrPointer_" is "_addrPointer.road

Value of 2@%Library.DynamicObject is New Road
```

​		`%Remove()` 语句破坏该属性并向属性值返回新的OREF。

```java
   set addrRemoved =  dynObj.%Remove("address")
   write "OREF of removed property: "_addrPointer,!,"OREF returned by %Remove(): "_addrRemoved

OREF of removed property: 2@%Library.DynamicObject
OREF returned by %Remove(): 3@%Library.DynamicObject
```

​		在调用 `%Remove()` 之后，`addrRemoved`包含对以前嵌入的动态对象的有效OREF。

```java
   write addrRemoved.%ToJSON()

{"road":"New Road"}

```

您可以使用 `%Remove()` 方法以任何顺序删除成员。这对对象和数组有不同的含义，如下例所示。

**（3）删除对象属性：**

​		对象属性没有固定的顺序。这意味着可以按任何顺序销毁属性，但删除属性并添加另一个属性也可能会更改序列化和返回属性的顺序。下面的示例创建了一个动态对象，并通过对 `%Set()` 的三次连续调用定义了三个属性：

```java
   set dynObject={}.%Set("propA","abc").%Set("PropB","byebye").%Set("propC",999)
   write dynObject.%ToJSON()

{"propA":"abc","PropB":"byebye","propC":999}
```

​		现在调用 `%Remove()` 来销毁属性`PropB`，然后添加新属性`PropD`。生成的动态对象不会按创建顺序序列化其属性：

```java
   do dynObject.%Remove("PropB")
   set dynObject.propD = "added last"
   write dynObject.%ToJSON()

{"propA":"abc","propD":"added last","propC":999}
```

这也会影响迭代器方法 `%GetNext()` 返回属性的顺序。有关使用 `%GetNext()` 的类似示例，请参阅使用 `%GetNext()` 对动态实体进行迭代。

**（4）删除数组元素：**

​		数组是从零开始的有序列表。当您对一个元素调用 `%Remove()` 时，该元素之后的所有元素的数组索引编号都将减1。以下示例连续三次调用 `%Remove(1)` ，每次都删除一个不同的元素：

```java
   set dynArray = ["a","b","c","d","e"]
   set removedValues = ""
   for i=1:1:3 { set removedValues = removedValues_dynArray.%Remove(1)_" " }
   write "Removed values: "_removedValues,!,"Array size="_dynArray.%Size()_": "_dynArray.%ToJSON()

Removed values: b c d
Array size=2: ["a","e"]
```

​		堆栈操作通常使用 `%Push()` 和 `%Pop()` 而不是 `%Set()` 和 `%Remove()` 来实现，但您可以通过将 `%Pop()` 替换为`%Remove(0)` 来实现队列（请参阅“将`%Push`和`%Pop`用于动态数组”）。

​		`%Remove()` 对所有数组的工作方式相同，包括包含未定义值的元素的数组。有关演示 `%Remove()` 如何处理稀疏数组的示例，请参阅“了解稀疏数组和未分配值”。

### 2.3.1 将动态实体指定为特性值

可以使用 `%Set()` 或 `%Push()` 将动态实体嵌套在另一个动态实体中。例如，可以将动态对象指定为属性值或数组元素。本章前面的示例演示了如何检索嵌套对象（请参阅“使用`%Get()`和`%Remove()`检索嵌套动态实体”）。下面的示例演示了创建嵌套对象的一种方法。

将动态实体指定为属性值

​		此示例创建了一个名为myData的属性的动态对象，该属性的值为另一个动态对象：

```java
   {"myData":{"myChild":"Value of myChild"}}
```

​		以下代码创建此对象。不需要将 `%Set()` 参数指定为变量，但这样做将允许您在运行时分配任何有效的名称或值：

```java
   set mainObj = {}
   set mainPropName="myData"

   set nestedObj = {}
   set nestedPropName="myChild"
   set nestedPropValue="Value of myChild"

   do nestedObj.%Set(nestedPropName, nestedPropValue)
   do mainObj.%Set(mainPropName,nestedObj)
   write mainObj.%ToJSON()
```

​		此代码生成以下输出：

```java
USER>write mainObj.%ToJSON()
{"myData":{"myChild":"Value of myChild"}}
```

*注：*

*不要将类型参数与对象值一起使用*

*`%Set()`方法有一个可选的类型参数，允许您在某些有限的情况下指定值参数的数据类型（请参阅“用`%Set()`或%`Push()`重写默认数据类型”)。当值参数是动态实体时，不能使用类型参数。如果尝试这样做，将引发错误。*



## 2.4 方法链

 `%Set()` 和 `%Push()` 方法返回对它们修改的实体的引用。返回的引用可以立即用于在同一表达式内调用同一实体上的另一个方法。

开始链的动态实体可以是构造函数（ `{}` 或 `[]` ）或现有实体。方法 `%Set()` 和 `%Push()` 返回可链接的引用，可以从链中的任何位置调用。链中的最后一项可以是实体可用的任何方法。

在以下示例中，单个write语句使用对 `%FromJSON()` 、 `%Set()` 、 `%Push()` 和 `%ToJSON()` 的链接调用来创建、修改和显示动态数组：

```java
   set jstring = "[123]"
   write [].%FromJSON(jstring).%Set(1,"one").%Push("two").%Push("three").%Set(1,"final value").%ToJSON()

[123,"final value","two","three"]
```

`%FromJSON()` 仅作为链中的第一个方法调用有用，因为它不会返回调用实体的修改版本。相反，它只是忽略调用实体并返回一个从JSON字符串反序列化的全新实例。有关更多信息，请参阅“将动态实体和JSON互转”。

您还可以通过使用 `%Get()` 、 `%Pop()` 、 `%CetNext()` 或 `%Remove()` 检索嵌套实体来启动链。



## 2.5 错误处理

动态实体在发生错误时抛出异常，而不是返回`%Status`。在以下示例中，抛出的异常包含足够的信息，可以断定方法参数中的第二个字符无效：

```java
   set invalidObject = {}.%FromJSON("{:}")

<THROW>%FromJSON+37^%Library.DynamicAbstractObject.1 *%Exception.General Parsing error 3 Line 1 Offset 2
```

在处理动态数据时，最好假设某些数据不符合您的期望。任何使用动态对象的代码都应该在某个级别上用 `TRY-CATCH` 块包围（请参阅使用ObjectScript中的“`TRY-CATCH`机制”）。例如：

```java
   TRY {
      set invalidObject = {}.%FromJSON("{:}")
   }
   CATCH errobj {
      write errobj.Name_", "_errobj.Location_", error code "_errobj.Code,!
      RETURN
   }

Parsing error, Line 1 Offset 2, error code 3
```



## 2.6 将动态实体和JSON互转

可以使用 `%ToJSON()` 方法序列化动态实体（将其转换为JSON字符串），使用 `%FromJSON()` 和 `%FromJSONFile()` 方法反序列化（将JSON转换为动态实体）。

**（1）将动态实体序列化为JSON：**

​		以下示例创建并修改动态对象，然后使用 `%ToJSON()` 对其进行序列化并显示结果字符串：

```java
   set dynObject={"prop1":true}.%Set("prop2",123).%Set("prop3","foo")
   set objString = dynObject.%ToJSON()
   write objString

{"prop1":true,"prop2":123,"prop3":"foo"}
```

​		动态数组的序列化方式相同：

```java
   set dynArray=[].%Push("1st value").%Push("2nd value").%Push("3rd value")
   set arrayString = dynArray.%ToJSON()
   write arrayString

["1st value","2nd value","3rd value"]
```

​		这两个示例都使用方法链接（请参阅本章前面的“方法链接”）。

**（2）将JSON反序列化为动态对象：**

​		`%FromJSON()` 方法将JSON字符串转换为动态实体。下面的示例构造一个动态数组并将其序列化为字符串jstring。对 `%FromJSON()` 的调用将jstring反序列化为名为newArray的新动态实体，然后对其进行修改并显示：

```java
   set jstring=["1st value","2nd value","3rd value"].%ToJSON()
   set newArray={}.%FromJSON(jstring)
   do newArray.%Push("new value")
   write "New entity:"_newArray.%ToJSON()

New entity:["1st value","2nd value","3rd value","new value"]
```

​		请注意，此示例从动态对象构造函数（ `{}` ）调用 `%FromJSON()` ，即使返回的值是动态数组。 `%FromJSON()` 是 `%DynamicAbstractObject` 的类方法，因此可以从任何动态实体或构造函数调用。

​		如果JSON数据存储在.JSON文件中，则可以使用 `%FromJSONFile()` 方法而不是 `%FromJSON()` 来反序列化数据。

**（3）使用 `%ToJSON()` 和 `%FromJSON()`：**

​		由于每次调用 `%FromJSON()` 都会创建一个新的动态实体，因此它可以用于复制现有实体或初始化一组相同的实体。

​		在以下示例中，属性 `dynObj.address` 的值是一个动态对象。该属性由变量 `addrPointer` 引用，通过调用 `%FromJSON()` 创建新的动态对象 `addrClone` 来克隆属性值：

```java
   set addrPointer.road = "Wright Ave."
   set addrClone.road = "Sinister Ave."
   write !,"Property = "_dynObj.address.%ToJSON(),!,"Clone = "_addrClone.%ToJSON()

Property = {"road":"Wright Ave."}
Clone = {"road":"Sinister Ave."}
```

​		如果JSON数据存储在.JSON文件中，则可以使用 `%FromJSONFile()` 方法而不是 `%FromJSON()` 方法克隆数据。

### 2.6.1 将大型动态实体序列化为流

如果动态实体足够大，`%ToJSON()` 的输出可能会超过字符串的最大长度（请参阅”服务器端编程方向指南“中的“字符串长度限制”）。本节中的示例使用名为`longStr`的最大长度字符串。以下代码片段演示如何生成longStr：

```java
   set longStr=""
   for i=1:1:$SYSTEM.SYS.MaxLocalLength() { set longStr = longStr_"x" }
   write "Maximum string length = "_$LENGTH(longStr)

Maximum string length = 3641144
```

当表达式使用 `%ToJSON()` 的返回值时，字符串将构建在程序堆栈上，该程序堆栈受字符串长度限制。例如，读/写语句，如 `write dyn.%ToJSON()` 或赋值语句，如 `set x=dyn.%ToJSON()` 将尝试将字符串放在堆栈上。以下示例将longStr的两个副本添加到动态数组，并尝试将序列化字符串分配给变量，导致ObjectScript返回<MAXSTRING>错误：

```java
   set longArray = [(longStr),(longStr)]
   set tooBig = longArray.%ToJSON()
```

```java
SET tooBig = longArray.%ToJSON()
^
<MAXSTRING>
```

这个问题的一般解决方案是在DO命令中通过引用传递 `%ToJSON()` 输出，而不实际检查返回值。输出直接写入当前设备，输出长度没有限制。在以下示例中，设备是一个流。

**（1）写入文件流：**

​		此示例将动态对象`longObject`写入文件，然后检索它。变量longStr是本节开头定义的值：

```java
   set longObject = {"a":(longStr),"b":(longStr)}
   set file=##class(%File).%New("c:\temp\longObjectFile.txt")
   do file.Open("WSN")
   do longObject.%ToJSON(file)
   do file.Close()

   do file.Open("RS")
   set newObject = {}.%FromJSONFile(file)
   write !,"Property newObject.a is "_$LENGTH(newObject.a)_" characters long."

Property newObject.a is 3641144 characters long.
```

此解决方案还可用于从其他流读取输入。

**（2）读取和写入全局字符流：**

​		在本例中，我们序列化了两个大型动态实体（使用临时流，因为 `%ToJSON()` 每个流只能序列化一个实体）。标准流处理方法用于将每个临时流存储为流bigLines中的单独行：

```java
   set tmpArray = ##class(%Stream.GlobalCharacter).%New()
   set dyn = [(longStr),(longStr)]
   do dyn.%ToJSON(tmpArray)

   set tmpObject = ##class(%Stream.GlobalCharacter).%New()
   set dyn = {"a":(longStr),"b":(longStr),"c":(longStr)}
   do dyn.%ToJSON(tmpObject)

   set bigLines = ##class(%Stream.GlobalCharacter).%New()
   do bigLines.CopyFrom(tmpArray)
   do bigLines.WriteLine()
   do bigLines.CopyFrom(tmpObject)
```

​		稍后，我们可以从bigLines反序列化每个动态实体：

```java
   do bigLines.Rewind()
   while ('bigLines.AtEnd) {
      write !,{}.%FromJSON(bigLines.ReadLineIntoStream())
   }

7@%Library.DynamicArray
7@%Library.DynamicObject

```



# 3 迭代数组

动态实体使用一个标准的迭代方法 `%GetNext()` ，它可以同时处理对象和数组。您还可以通过顺序寻址每个元素（使用for循环或类似结构）来遍历数组，但这可能需要一些稀疏数组的知识，因为稀疏数组的元素不包含值。由于 `%GetNext()` 通过跳过这些元素来避免问题，因此只要可能，它应该是首选的迭代方法。

本章讨论何时以及如何使用每种迭代方法。包括以下主题：

- 使用 `%GetNext()` 在动态实体上迭代
- 了解稀疏数组和未分配的值
  - 使用 `%Size()` 进行稀疏数组迭代
  - 使用 `%IsDefined()` 测试有效值
- 在动态数组中使用 `%Push` 和 `%Pop`



## 3.1 使用 `%GetNext()` 在动态实体上迭代

所有动态实体都提供 `%GetIterator()` 方法，该方法返回 `%Iterator` 的实例（ `%Iterator.Object` 或 `%Iterator.Array` ），该实例包含指向动态对象或数组成员的指针。 `%Iterator` 对象提供了一个 `%GetNext()` 方法来获取每个成员的键和值。

每次调用 `%GetNext()` 方法都会使迭代器游标前进，如果它位于有效成员上，则返回1（true）；如果它位于最后一个成员之外，则返回0（false）。成员的名称或索引号在第一个输出参数中返回，值在第二个输出参数。例如：

```java
   set test = ["a","b","c"]  // dynamic arrays are zero-based
   set iter = test.%GetIterator()
   while iter.%GetNext(.key, .value) { write "element:"_key_"=/"_value_"/  "}

element:0=/a/  element:1=/b/  element:2=/c/
```

迭代器光标只在一个方向上移动；它不能返回到前一个成员或以相反的顺序迭代数组。

在稀疏数组上迭代时，迭代器跳过没有赋值的元素。在对象上迭代时，属性不一定以可预测的顺序返回。下面的示例演示了数组迭代和对象迭代之间的这些差异。

**（1）在数组上迭代** 

​		此示例创建稀疏数组。该数组从零开始，有六个元素，但只有元素0、1和5具有赋值。JSON字符串中显示的空元素只是未分配值的占位符：

```java
   set dynArray=["abc",999]
   set dynArray."5" = "final"
   write dynArray.%Size()_" elements: "_dynArray.%ToJSON()

6 elements: ["abc",999,null,null,null,"final"]
```

​		`%GetNext()` 将只返回具有值的三个元素，跳过所有未分配的元素：

```java
   set iterator=dynArray.%GetIterator()
   while iterator.%GetNext(.key,.val) { write !, "Element index: "_key_", value: "_val }

Element index: 0, value: abc
Element index: 1, value: 999
Element index: 5, value: final
```

​		有关稀疏数组的详细信息，请参阅下一节（“了解稀疏数组和未分配值”）。

**（2）在对象上迭代**

​		对象属性没有固定的顺序，这意味着可以按任何顺序创建和销毁属性，而无需创建未分配的值，但更改对象也可能会更改 `%GetNext()` 返回属性的顺序。以下示例创建一个具有三个属性的对象，调用 `%Remove()` 销毁一个属性，然后添加另一个属性：

```java
   set dynObject={"propA":"abc","PropB":"byebye","propC":999}
   do dynObject.%Remove("PropB")
   set dynObject.propD = "final"
   write dynObject.%Size()_" properties: "_dynObject.%ToJSON()

3 properties: {"propA":"abc","propD":"final","propC":999}
```

​		当我们遍历对象时， `%GetNext()` 不会按创建顺序返回项目：

```java
   set iterator=dynObject.%GetIterator()
   while iterator.%GetNext(.key,.val) { write !, "Property name: """_key_""", value: "_val }

Property name: "propA", value: abc
Property name: "propD", value: final
Property name: "propC", value: 999
```



## 3.2 了解稀疏数组和未分配的值

动态数组可以是稀疏数组，这意味着不是数组的所有元素都包含值。例如，您可以为动态数组的元素100赋值，即使该数组尚未包含元素0到99。存储器中的空间仅分配给元素100处的值。元素0到99未赋值，这意味着0到99是有效的元素标识符，但不指向内存中的任何值。 `%Sizee()` 方法返回的数组大小为101，但 `%GetNext()` 方法将跳过未分配的元素，只返回元素100中的值。

以下示例通过向元素8和11分配新值来创建稀疏数组：

```java
   set array = ["val_0",true,1,"",null,"val_5"] // values 0 through 5
   do array.%Set(8,"val_8")                     // undefined values 6 and 7 will be null
   set array."11" = "val_11"                    // undefined values 9 and 10 will be null
   write array.%ToJSON()

["val_0",true,1,"",null,"val_5",null,null,"val_8",null,null,"val_11"]
```

**在稀疏阵列中使用 `%Remove`**

​		`%Remove()` 方法像对待任何其他元素一样对待未分配的元素。可以有一个仅由未分配值组成的数组。以下示例创建一个稀疏数组，然后删除未分配的元素0。然后删除元素7，它现在是唯一包含值的元素：

```java
   set array = []
   do array.%Set(8,"val_8")
   do array.%Remove(0)
   do array.%Remove(7)
   write "Array size = "_array.%Size()_":",!,array.%ToJSON()

Array size = 7:
[null,null,null,null,null,null,null]
```

​		有关演示 `%Remove()` 的更多示例，请参阅“使用%Set()、%Get()和%Remove()”。

*注：*

*JSON无法保留空值和未赋值之间的区别*

*动态实体包含允许它们区分空值和未分配值的元数据。JSON没有指定单独的未定义数据类型，因此当动态实体序列化为JSON字符串时，没有规范的方法来保持这种区别。如果不希望序列化数据中有额外的空值，则必须在序列化之前删除未分配的元素（请参阅“使用`%IsDefined()`测试有效值”），或者使用一些依赖于应用程序的方法将差异记录为元数据。*

### 3.2.1 使用 `%Size()` 进行稀疏数组迭代

`%Size()` 方法返回动态实体中属性或元素的数量。例如：

```java
   set dynObject={"prop1":123,"prop2":[7,8,9],"prop3":{"a":1,"b":2}}
   write "Number of properties: "_dynObject.%Size()

Number of properties: 3
```

在稀疏数组中，此数字包括具有未赋值的元素，如以下示例所示。本例中创建的数组有六个元素，但只有元素0、1和5具有赋值。JSON字符串中显示的空元素只是未分配值的占位符：

```java
   set test=["abc",999]
   set test."5" = "final"
   write test.%Size()_" elements: "_test.%ToJSON()

6 elements: ["abc",999,null,null,null,"final"]
```

元素2、3和4没有赋值，但仍被视为有效的数组元素。动态数组是从零开始的，因此最终元素的索引编号始终为%Size()-1。以下示例以相反的顺序遍历数组测试的所有六个元素，并使用 `%Get()` 返回它们的值：

```java
   for i=(test.%Size()-1):-1:0 {write "element "_i_" = /"_test.%Get(i)_"/",!}

element 5 = /final/
element 4 = //
element 3 = //
element 2 = //
element 1 = /999/
element 0 = /abc/
```

对于大于`%Size()-1`的数字， `%Get()` 方法将返回“”（空字符串），对于负数将抛出异常。有关如何区分未赋值、空字符串和空值的信息，请参阅“使用数据类型”。

*注：*

*这里所示的迭代技术仅用于特殊目的（例如检测数组中未分配的值或以相反的顺序迭代数组）。在大多数情况下，您应该使用 `%GetNext()` ，它跳过未分配的元素，可以用于动态对象和动态数组。有关详细信息，请参阅上一节（“使用%GetNext()遍历动态实体”）。*

### 3.2.2 使用 `%IsDefined()` 测试有效值

`%IsDefined()`方法测试在指定的属性名称或数组索引号处是否存在值。如果指定的成员具有值，则该方法返回1（true），如果该成员不存在，则返回0（false）。对于稀疏数组中没有赋值的元素，它也将返回false。

如果使用for循环遍历稀疏数组，将遇到未分配的值。下面的示例创建了一个数组，其中前三个元素是JSON null、空字符串和未赋值。for循环故意设置为经过数组的末尾，并测试数组索引为4的元素：

```java
   set dynarray = [null,""]
   set dynarray."3" = "final"
   write dynarray.%ToJSON()
[null,"",null,"final"]

   for index = 0:1:4 {write !,"Element "_index_": "_(dynarray.%IsDefined(index))}

Element 0: 1
Element 1: 1
Element 2: 0
Element 3: 1
Element 4: 0
```

`%IsDefined()` 在两种情况下返回0：元素2没有赋值，元素4不存在。

ObjectScript为JSON空值返回“”（空字符串），如本例中的元素0。如果需要测试“”和空值以及未分配值，请使用 `%GetTypeOf()` 而不是 `%IsDefined()` （请参阅“解析空值、空字符串和未分配值”）。

```java
   set names = ["prop1","prop2","noprop"]
   set dynobj={}.%Set(names."0",123).%Set(names."1",456)
   write dynobj.%ToJSON()

{"prop1":123,"prop2":456}
```

以下代码使用 `%IsDefined()` 确定哪些字符串已用作dynobj中的属性名：

```java
   for name = 0:1:2 {write !,"Property "_names.%Get(name)_": "_(dynobj.%IsDefined(names.%Get(name)))}

Property prop1: 1
Property prop2: 1
Property noprop: 0
```



## 3.3 在动态数组中使用 `%Push` 和 `%Pop`

`%Push()` 和 `%Pop()` 方法仅适用于动态数组。它们的工作方式与 `%Set()` 和 `%Remove()` 完全相同，只是它们总是添加或删除数组的最后一个元素。例如，以下代码使用任意一组方法生成相同的结果（有关在同一语句中多次调用 `%set()` 或 `%Push()` 的详细信息，请参阅“方法链接”）：

```java
   set array = []
   do array.%Set(array.%Size(), 123).%Set(array.%Size(), 456)
   write "removed "_array.%Remove(array.%Size()-1)_", leaving "_array.%ToJSON()

removed 456, leaving [123]

   set array = []
   do array.%Push(123).%Push(456)
   write "removed "_array.%Pop()_", leaving "_array.%ToJSON()

removed 456, leaving [123]
```

虽然 `%Push()` 和 `%Pop()` 用于堆栈操作，但您可以通过用 `%Remove(0)` 代替 `%Pop()` 来实现队列。

以下示例使用 `%Push()` 构建一个数组，然后使用 `%Pop()` 以相反的顺序删除每个元素。

**使用`%Push()`和`%Pop()`构建数组并将其删除：**

​		构建包含嵌套数组的数组。对 `%Push()` 的最后调用指定了可选类型参数，以将布尔值存储为JSON false，而不是ObjectScript 0（请参阅“用%Set()或%Push()重写默认数据类型”）：

```java
   set array=[]
   do array.%Push(42).%Push("abc").%Push([])
   do array."2".%Push("X").%Push(0,"boolean")
   write array.%ToJSON()

[42,"abc",["X",false]]
```

​		删除嵌套数组的所有元素。与所有动态实体方法一样，`%Pop()` 将返回ObjectScript 0而不是JSON false：

```java
   for i=0:1:1 {write "/"_array."2".%Pop()_"/ "}
/0/ /X/

   write array.%ToJSON()
[42,"abc",[]]
```

​		现在移除主数组的所有元素，包括空嵌套数组：

```java
   for i=0:1:2 {write "/"_array.%Pop()_"/ "}
/2@%Library.DynamicArray/ /abc/ /42/

   write array.%ToJSON()
[]
```

​		为了简单起见，这些示例使用硬编码for循环。请参阅“使用%Sizee()进行稀疏数组迭代”，以获得更真实的数组迭代示例。



# 4 使用数据类型

ObjectScript没有等同于JSON `true`、`false`和`null`的不同常量，JSON也没有具有未定义值的数组元素的概念。本章讨论了这些不匹配，并描述了为处理这些不匹配而提供的工具。

- 使用`%GetTypeOf()`查找值的数据类型
- 用`%Set()`或`%Push()`重写默认数据类型
- 解析JSON空值和布尔值
- 解析`Null`、空字符串和未分配的值



## 4.1 使用`%GetTypeOf()`查找值的数据类型

可以使用`%GetTypeOf()`方法获取动态实体成员的数据类型。动态对象属性或数组元素可以具有以下任意一种数据类型：

- 对象数据类型：
  - array—动态数组引用
  - object-动态对象引用
  - oref-对不是动态实体的对象的引用
- 文字值：
  - number-规范数值
  - string-字符串文本或计算为字符串文本的表达式
- JSON文本：
  - boolean-JSON文本true或false
  - null-JSON文本null
- 无数据类型：
  - unassigned-属性或元素存在，但没有赋值。

**对对象使用%GetTypeOf：**

​		对对象使用此方法时，参数是属性的名称。例如：

```java
   set dynobj={"prop1":123,"prop2":[7,8,9],"prop3":{"a":1,"b":2}}
   set iter = dynobj.%GetIterator()
   while iter.%GetNext(.name) {write !,"Datatype of "_name_" is "_(dynobj.%GetTypeOf(name))}

Datatype of prop1 is number
Datatype of prop2 is array
Datatype of prop3 is object
```

**对数组使用%GetTypeOf:**

​		将此方法用于数组时，参数是元素的索引。下面的示例检查稀疏数组，其中元素2没有赋值。该示例使用`for`循环，因为`%GetNext()`将跳过未分配的元素：

```java
   set dynarray = [12,34]
   set dynarray."3" = "final"
   write dynarray.%ToJSON()
[12,34,null,null,"final"]

   for index = 0:1:3 {write !,"Datatype of "_index_" is "_(dynarray.%GetTypeOf(index))}
Datatype of 0 is number
Datatype of 1 is number
Datatype of 2 is unassigned
Datatype of 3 is string
```

**区分数组或对象和oref:**

​		动态实体的数据类型将是数组或对象。非动态实体的InterSystems IRIS对象的数据类型为oref。在下面的示例中，对象`dyn`的每个属性都是这三种数据类型之一。属性`dynobject`为类`%DynamicObject`，属性`dyarray`为%`DynamicArray`，而属性`streamobj`为`%Stream.GlobalCharacter`：

```java
   set dyn={"dynobject":{"a":1,"b":2},"dynarray":[3,4],"streamobj":(##class(%Stream.GlobalCharacter).%New())}
   set iterator=dyn.%GetIterator()
   while iterator.%GetNext(.key,.val) { write !, "Datatype of "_key_" is: "_dyn.%GetTypeOf(key) }

Datatype of dynobject is: object
Datatype of dynarray is: array
Datatype of streamobj is: oref

```



## 4.2 用`%Set()`或`%Push()`重写默认数据类

默认情况下，系统会自动将`%Set()`或`%Push()`值参数解释为对象数据类型（对象、数组或oref）或ObjectScript文本数据类型（字符串或数字）。不能直接将JSON文本null、true或false作为值传递，因为参数被解释为ObjectScript文本或表达式。例如，以下代码引发错误，因为值true被解释为变量名：

```java
   do o.%Set("prop3",true)

DO o.%Set("prop3",true)
^
<UNDEFINED> *true
```

ObjectScript使用""（空字符串）表示null，0表示布尔值false，非零数字表示布尔值true。为了解决这个问题，`%Set()`和`%Push()`使用可选的第三个参数来指定值的数据类型。第三个参数可以是JSON布尔值或null。例如：

```java
   write {}.%Set("a",(2-4)).%Set("b",0).%Set("c","").%ToJSON()
{"a":-2,"b":0,"c":""}

   write {}.%Set("a",(2-4),"boolean").%Set("b",0,"boolean").%Set("c","","null").%ToJSON()
{"a":true,"b":false,"c":null}
```

如果值可以解释为数字，则第三个参数也可以是字符串或数字：

```java
   write [].%Push("023"_"04").%Push(5*5).%ToJSON()
["02304",25]

   write [].%Push(("023"_"04"),"number").%Push((5*5),"string").%ToJSON()
[2304,"25"]
```



## 4.3 解析JSON空值和布尔值

在JSON语法中，值true、false和null与值1、0和""（空字符串）不同，但ObjectScript不做此区分。当从元素或属性中检索JSON值时，它们总是转换为与ObjectScript兼容的值。这意味着JSON true始终返回为1，false返回为0，null返回为""。在大多数情况下，这将是所需的结果，因为返回值可以在ObjectScript表达式中使用，而无需首先将其从JSON格式转换。动态实体在内部保留原始JSON或ObjectScript值，因此如果需要，可以使用`%GetTypeOf()`来标识实际的数据类型。

在以下示例中，动态数组构造函数指定JSON true、false和null值、数值和字符串文字值以及ObjectScript动态表达式（其计算结果为ObjectScript布尔值1和0）：

```java
   set test = [true,1,(1=1),false,0,(1=2),"",null]
   write test.%ToJSON()
```

```java
[true,1,1,false,0,0,"",null]
```

如上所述，构造函数中分配的值已保存在生成的动态数组中，并在序列化为JSON字符串时正确显示。

以下示例检索并显示数组值。正如预期的那样，JSON值true、false和null被转换为ObjectScript兼容的值1、0和“”：

```java
   set iter = test.%GetIterator()
   while iter.%GetNext(.key,.val){write "/"_val_"/ "}
```

```java
/1/ /1/ /1/ /0/ /0/ /0/ // //
```

此示例使用`%GetNext()`，但如果使用`%get()`、`%Pop()`或点语法检索值，则会得到相同的结果。

必要时，可以使用`%GetTypeOf()`方法来发现值的原始数据类型。例如：

```java
   set iter = test.%GetIterator()
   while iter.%GetNext(.key,.val) {write !,key_": /"_test.%Get(key)_"/ = "_test.%GetTypeOf(key)}
```

```java
0: /1/ = boolean
1: /1/ = number
2: /1/ = number
3: /0/ = boolean
4: /0/ = number
5: /0/ = number
6: // = string
7: // = null
```

*注：*

*动态对象中的数据类型*

​		*尽管本章重点介绍动态数组，但相同的数据类型转换适用于动态对象值。如果将动态数组测试替换为以下动态对象，本节中的示例将完全相同：*

```java
   set test = {"0":true,"1":1,"2":(1=1),"3":false,"4":0,"5":(1=2),"6":"","7":null}
```

*除了这一行之外，不需要更改任何示例代码。此对象中的属性名是与原始数组的索引号相对应的数字字符串，因此即使输出也将相同。*



## 4.4 解析`Null`、空字符串和未分配的值

尽管您可以为元素或属性分配JSON空值，但该值将始终返回为""（ObjectScript空字符串）。如果尝试获取未分配元素的值，也将返回空字符串。您可以使用`%GetTypeOf()`来识别每种情况下的实际数据类型。

此示例将测试包含JSON空值和空字符串的稀疏数组。尽管数组元素2没有赋值，但它将在JSON字符串中用null表示：

```java
   set array = [null,""]
   do array.%Set(3,"last")
   write array.%ToJSON()
```

```java
[null,"",null,"last"]
```

在大多数情况下，您可以使用`%GetNext()`来检索数组值，但本示例使用`for`循环来返回`%GetNext()`将跳过的未分配值。最后一个元素的索引编号为`array.%Size()-1`，但循环计数器故意设置为超过数组的末尾：

```java
   for i=0:1:(array.%Size()) {write !,i_". value="""_array.%Get(i)_""" type="_array.%GetTypeOf(i)}
```

```java
0. value="" type=null
1. value="" type=string
2. value="" type=unassigned
3. value="last" type=string
4. value="" type=unassigned
```

在此示例中，`%Get()`在四种不同的情况下返回一个空字符串：

1. 元素0是JSON空值，`%GetTypeOf()`将其标识为数据类型null。
2. 元素1是一个空字符串，它被标识为数据类型字符串。
3. 元素2没有值，被标识为未分配的数据类型。
4. 尽管元素3是数组中的最后一个元素，但该示例尝试为不存在的元素4获取数据类型，该元素也被标识为未分配的数据类型。有效的数组索引号将始终小于数组。`%Size()`。

*注：*

*null和未赋值之间的区别是当动态实体序列化为JSON字符串时不会保留的ObjectScript元数据。所有未分配的元素都将序列化为空值。有关详细信息，请参阅“了解稀疏数组和未分配值”。*



# 5 动态实体方法快速参考

本节提供了每个可用动态实体方法的概述和参考。动态实体是`%Library.DynamicObject`或`%Library.DynamicArray`的实例，这两个实例都扩展了`%Library_DynamicAbstractObject`。本章中的每个列表都包含指向相应在线类参考文档的链接。

本节列出了所有可用的动态实体方法，简要描述了每种方法，并提供了更多信息的链接。所有方法都可用于对象和数组，但`%Push()`和`%Pop()`除外，它们仅适用于数组。

## 5.1 方法详细信息

### `%FromJSON()`

给定JSON源，解析源并在包含解析的JSON返回数据类型为`%DynamicAbstractObject`的对象。如果在分析过程中发生错误，将引发异常。有关详细信息和示例，请参阅“将动态实体转换为JSON”。

```java
   classmethod %FromJSON(str) as %DynamicAbstractObject
```

参数：

- str-输入可以来自以下任何一个源：
  - 包含源的字符串值。
  - 要从中读取源的流对象。

另请参阅：`%FromJSONFile()`，`%ToJSON()`，将大型动态实体序列化为流

类引用：`%DynamicAbstractObject.%FromJSON()`

### `%FromJSONFile()`

给定JSON源，解析源并在包含解析的JSON返回数据类型为`%DynamicAbstractObject`的对象。如果在分析过程中发生错误，将引发异常。有关详细信息和示例，请参阅“将动态实体转换为JSON”。

```java
   classmethod %FromJSONFile(filename) as %DynamicAbstractObject
```

参数：

- filename—可以读取源的文件URI的名称。文件必须编码为UTF-8。

另请参阅：`%FromJSONFile()`，`%ToJSON()`，将大型动态实体序列化为流

类引用：`%DynamicAbstractObject.%FromJSON()`

### `%Get()`

给定有效的对象键或数组索引，返回值。如果该值不存在，则返回空字符串""。有关详细信息和示例，请参阅“使用`%Set()`、`%Get()`和`%Remove()`”。

```java
   method %Get(key) as %RawString
```

参数：

- key-要检索的值的对象键或数组索引。数组索引必须作为规范整数值传递。数组索引从位置0开始。

另请参阅： `%Set()`, `%Remove()`, `%Pop()`

类引用：`%DynamicObject.%Get()`和 `%DynamicArray.%Get()`

### `%GetIterator()`

返回允许对动态实体的所有成员进行迭代的`%Iterator`对象。有关详细信息和示例，请参阅“使用`%GetNext()`遍历动态实体”。

```java
   method %GetIterator() as %Iterator.AbstractIterator
```

另请参阅：`%GetNext()`

类引用：`%DynamicObject.%GetIterator()`,`%DynamicArray.%GetIterator()`,`%Iterator.Object`,`%Iterator.Array`

### `%GetNext()`

这是`%GetIterator()`返回的`%Iterator`对象的方法。它使迭代器前进，如果迭代器位于有效元素上，则返回true，如果它位于最后一个元素之外，则返回false。键和值参数返回当前迭代器位置处有效元素的值。有关详细信息和示例，请参阅“使用`%GetNext()`遍历动态实体”。

```java
   method getNext(Output key, Output value) as %Integer
```

参数：

- key-返回当前位置元素的对象键或数组索引
- value-返回元素在当前位置的值。

另请参阅：`%GetIterator()`

类引用：`%Iterator.Object.%GetNext()`,`%Iterator.Array.%GetNext()`

### `%GetTypeOf()`

给定有效的对象键或数组索引，返回一个字符串，指示值的数据类型。有关详细信息和示例，请参阅“使用数据类型”。

```java
   method %GetTypeOf(key) as %String
```

参数：

- key-要测试的值的对象键或数组索引。

返回值：

将返回以下字符串之一：

- "null"-JSON null
- "boolean"-零（“false”）或非零（“true”）数值
- "number"-任何规范数值
- "oref"-对另一个对象的引用
- "object"-嵌套对象
- "array"-嵌套数组
- "string"-标准文本字符串
- "unassigned"-属性或元素存在，但没有赋值

另请参阅：`%IsDefined()`

类引用：`%DynamicAbstractObject.%GetTypeOf()`

### `%IsDefined()`

测试键指定的项是否在对象中定义。如果项未分配或不存在，则返回false。有关详细信息和示例，请参阅“使用`%IsDefined()`测试有效值”。

```java
   method %IsDefined(key) as %Boolean
```

参数：

- key-要测试的项目的对象键或数组索引。数组索引必须作为规范整数值传递。数组索引从位置0开始。

另请参阅：解析Null、空字符串和未分配的值

类引用：`%DynamicObject.%IsDefined()`和`%DynamicArray.%IsDefined()`

### `%Pop()`

返回数组的最后一个成员的值。然后从数组中删除该值。如果数组已经为空，则该方法返回空字符串""。有关详细信息和示例，请参阅“将`%Push`和`%Pop`用于动态阵列”。

```java
   method %Pop() as %RawString
```

另请参阅：`%Push()`, `%Get()`, `%Remove()`,解析Null、空字符串和未分配的值

类引用：`%DynamicArray.%Pop()`

### `%Push()`

给定一个新值，将其附加到当前数组的末尾，从而增加数组的长度。返回指向当前已修改数组的oref，以便可以链接对`%Push()`的调用。有关详细信息和示例，请参阅“将`%Push`和`%Pop`用于动态阵列”。

```java
   method %Push(value, type) as %DynamicAbstractObject
```

参数：

- value—要分配给新数组元素的值。

- type—（可选）表示值的数据类型的字符串。可以使用以下字符串：

  - "null"-JSON null。值参数必须为""（空字符串）。

  - "boolean"-JSON false（值参数必须为0）或true（值参数为1）。

  - "false"-JSON false（值参数必须为0）。

  - "true"-JSON true（值参数必须为1）。

  - "number"-将值转换为规范数值。

  - "string"-将值转换为文本字符串。

    注意：如果指定的值是对象或oref，则不能使用可选类型参数。例如，如果指定的值是动态实体，则无论为类型指定什么值，都会引发错误。有关详细信息，请参阅“用`%Set()`或`%Push()`重写默认数据类型”。

另请参阅：`%Pop()`, `%Set()`, 方法链

类引用：`%DynamicArray.%Push()`

### `%Remove()`

从动态对象或数组中删除指定的元素，并返回所删除元素的值。如果元素的值是嵌入的动态对象或数组，则所有从属节点也将被删除。在动态数组中，被删除元素之后的所有元素的下标位置将减1。有关详细信息和示例，请参阅“使用`%Set()`、`%Get(`)和`%Remove()`”。

```java
   method %Remove(key) as %DynamicAbstractObject
```

参数：

- key-要删除的元素的对象键或数组索引。数组索引必须作为规范整数值传递。数组索引从位置0开始。

另请参阅：`%Set()`, `%Get()`, `%Pop()`

类引用：`%DynamicObject.%Remove()`和`%DynamicArray.%Remove()`

### `%Set()`

创建新值或更新现有值。返回对已修改数组的引用，允许嵌套对`%Set()`的调用。有关详细信息和示例，请参阅“使用`%Set()`、`%Get()`和`%Remove()`”。

```java
   method %Set(key, value, type) as %DynamicAbstractObject
```

参数：

- key-要创建或更新的值的对象键或数组索引。数组索引必须作为规范整数值传递。数组索引从位置0开始。
- value-用于更新先前值或创建新值的新值。
- type-（可选）表示值的数据类型的字符串。可以使用以下字符串：
  - "null"-JSON null。值参数必须为""（空字符串）。
  - "boolean"-JSON false（值参数必须为0）或true（值参数为1）。
  - "false"-JSON false（值参数必须为0）。
  - "true"-JSON true（值参数必须为1）。
  - "number"-将值转换为规范数值。
  - "string"-将值转换为文本字符串。

### `%Size()`

返回显示动态对象或数组大小的整数。对于数组，大小包括数组中未分配的条目。对于对象，大小仅包括具有指定值的元素。有关详细信息和示例，请参阅“使用`%Sizee()`进行稀疏阵列迭代”。

```java
   method %Size() as %Integer
```

另请参阅：`%GetNext()`

类引用：`%DynamicAbstractObject.%Size()`

### `%ToJSON()`

转换`%DynamicAbstractObject`的实例。转换为JSON字符串。有关详细信息和示例，请参阅“将动态实体转换为JSON”。

```java
   method %ToJSON(outstrm As %Stream.Object) as %String
```

参数：

- outstrm-可选。有多种可能性：
  - 如果未指定outstrm，并且通过DO调用该方法，则JSON字符串将写入当前输出设备。
  - 如果未指定outstrm，并且该方法作为表达式调用，则JSON字符串将成为表达式的值。
  - 如果将outstrm指定为`%Stream.Object`的实例，则JSON字符串将写入流（有关详细信息和示例，请参阅“将大型动态实体序列化为流”）。
  - 如果outstrm是一个对象，但不是%Stream.Object的实例，则将引发异常。
  - 如果outstrm不是对象且不为空，则假定它是完全限定的文件规范（必须定义文件的完整路径）。该文件链接到新创建的%Stream.FileCharacter流中，JSON字符串被写入到流中，并在完成时将流保存到文件中。

另请参阅：`%FromJSON()`, `%FromJSONFile()`

类引用：` %DynamicAbstractObject.%ToJSON()`



# 6 JSON Adaptor介绍

JSON Adaptor是一种将ObjectScript对象（注册的、串行的或持久的）映射到JSON文本或动态实体的方法。本章涵盖以下主题：

- 导出和导入-引入启用JSON的对象，并演示`%JSON.Adaptor`导入和导出方法。
- 参数映射-描述控制对象属性如何转换为JSON字段的属性参数。
- 使用XData映射块-描述了将多个参数映射应用于单个类的方法。
- 格式化JSON-演示如何使用`%JSON.Formatter`格式化JSON字符串。



## 6.1 导出和导入

要从JSON序列化或从JSON序列化的任何类都需要子类`%JSON.Adaptor`，包括以下方法：

- `%JSONExport()`将启用JSON的类序列化为JSON文档，并将其写入当前设备。
- `%JSONExportToStream()`将启用JSON的类序列化为JSON文档并将其写入流。
- `%JSONExportToString()`将启用JSON的类序列化为JSON文档，并将其作为字符串返回。
- `%JSONImport()`将JSON作为字符串或流导入，或导入`%DynamicAbstractObject`的子类，并返回启用JSON的类的实例。

为了演示这些方法，本节中的示例将使用以下两个类：

**（1）支持JSON的类`Model.Event`和`Model.Location`**

```java
  Class Model.Event Extends (%Persistent, %JSON.Adaptor)
  {
    Property Name As %String;
    Property Location As Model.Location;
  }
```

```java
  Class Model.Location Extends (%Persistent, %JSON.Adaptor)
  {
    Property City As %String;
    Property Country As %String;
  }
```

如您所见，我们有一个持久事件类，它链接到一个位置。这两个类都继承自`%JSON.Adaptor`。这使我们能够填充对象图并将其直接导出为JSON字符串。

**（2）将对象导出为JSON字符串**

```java
  set event = ##class(Model.Event).%New()
  set event.Name = "Global Summit"
  set location = ##class(Model.Location).%New()
  set location.Country = "United States of America"
  set event.Location = location
  do event.%JSONExport()
```

此代码显示以下JSON字符串：

```java
  {"Name":"Global Summit","Location":{"City":"Boston","Country":"United States of America"}}
```

可以使用`%JSONExportToString()`而不是`%JSONExport()`将JSON字符串分配给变量：

```java
  do event.%JSONExportToString(.jsonEvent)
```

最后，可以使用`%JSONImport()`将JSON字符串转换回对象。此示例从上一示例中获取字符串变量`jsonEvent`，并将其转换回`Model.Event`对象：

**（3）将JSON字符串导入对象**

```java
  set eventTwo = ##class(Model.Event).%New()
  do eventTwo.%JSONImport(jsonEvent)
  write eventTwo.Name,!,eventTwo.Location.City

```

```
  Global Summit
  Boston
```

导入和导出都适用于任意嵌套的结构。



## 6.2 参数映射

通过设置相应的参数，可以为每个单独的属性指定映射逻辑。（如果您熟悉的`%XML.Adaptor`，这是一个类似的过程）。

我们可以通过指定属性参数来更改`Model.Event`类（在上一节中定义）的映射：

```java
  Class Model.Event Extends (%Persistent, %JSON.Adaptor)
  {
    Property Name As %String(%JSONFIELDNAME = "eventName");
    Property Location As Model.Location(%JSONINCLUDE = "INPUTONLY");
  }
```

此映射引入了两个更改：

- 属性Name将映射到名为eventName的JSON字段。
- Location属性仍将被`%JSONImport()`用作输入，但`%JSONExport()`和其他导出方法将忽略它。

之前，在未修改的`Model.Event`类的实例上调用`%JSONExport()`，并返回以下JSON字符串：

```java
  {"Name":"Global Summit","Location":{"City":"Boston","Country":"United States of America"}}
```

如果我们对重新映射的`Model.Event`的实例调用`%JSONExport()`（使用相同的属性值），将返回以下字符串：

```java
  {"eventName":"Global Summit"}

```

有多种参数可用于调整映射：

- `%JSONFIELDNAME`（仅限属性）设置要用作JSON内容中字段名的字符串（默认值为属性名）。
- `%JSONIGNOREINVALIDFIELD`控制JSON输入中意外字段的处理。
- `%JSONIGNORENULL`允许开发人员覆盖字符串属性的空字符串的默认处理。
- `%JSONINCLUDE`（仅限属性）指定此属性是否将包含在JSON输出或输入中（有效值为“inout”（默认值）、“outputonly”、“inputOnly”或“none”）。
- `%JSONNULL`指定如何存储字符串属性的空字符串。
- `%JSONREFERENCE`指定如何将对象引用投射到JSON字段。选项包括“OBJECT”（默认值）、“ID”、“OID”和“GUID”。

有关详细信息，请参阅本章后面的参考部分“`%JSON.Adaptor`类和属性参数”。



## 6.3 使用XData映射块

您可以在特殊的XData mapping块中指定映射，并在调用导入或导出方法时应用映射，而不是在属性级别上设置映射参数。

下面的代码定义了前两节中使用的`Model.Event`类的另一个版本。在此版本中，没有指定属性参数，但我们定义了一个名为`OnlyLowercaseTopLevel`的XData Mapping块，该块指定了与前一版本中的属性相同的参数设置：

```java
  Class Model.Event Extends (%Persistent, %JSON.Adaptor)
  {
    Property Name As %String;
    Property Location As Model.Location;

    XData OnlyLowercaseTopLevel
    {
      <Mapping xmlns="http://www.intersystems.com/jsonmapping">
        <Property Name="Name" FieldName="eventName"/>
        <Property Name="Location" Include="INPUTONLY"/>
      </Mapping>
    }
  } 

```

有一个重要的区别：XData块中的JSON映射不会改变默认行为，但可以通过在导入和导出方法的可选`%mappingName`参数中指定块名来应用它们。例如：

```java
  do event.%JSONExport("OnlyLowercaseTopLevel")

```

显示：

```
  {"eventName":"Global Summit"}
```

就像在属性定义中指定了参数一样。

如果没有具有所提供名称的XData块，则将使用默认映射。使用这种方法，您可以配置多个映射，并单独引用每个调用所需的映射，从而在使映射更灵活和可重用的同时授予您更多的控制权。

### 6.3.1 定义XData映射块

启用JSON的类可以定义任意数量的附加映射。每个映射都在以下形式的单独XData块中定义：

```java
  XData {MappingName}
  {
    <Mapping  {ClassAttribute}="value" [...] xmlns="http://www.intersystems.com/jsonmapping".>
      <{Property Name}="PropertyName" {PropertyAttribute}="value" [...] />
      [... more Property elements]
    </Mapping>
  }

```

其中{MappingName}, {ClassAttribute}, {Property Name}, 和 {PropertyAttribute}的定义如下：

- MappingName：`%JSONREFERENCE`参数或Reference属性使用的映射的名称。
- ClassAttribute：指定映射的类参数。可以定义以下类属性：
  - Mapping-要应用的XData映射块的名称。
  - IgnoreInvalidField-指定类参数`%JSONIGNOREINVALIDFIELD`。
  - Null-指定类参数`%JSONNULL`。
  - IgnoreNull-指定类参数`%JSONIGNORENNULL`。
  - Reference-指定类参数`%JSONREFERENCE`。
- PropertyName：正在映射的属性的名称。
- PropertyAttribute：指定映射的属性参数。可以定义以下属性：
  - FieldName-指定属性参数`%JSONFIELDNAME`（默认情况下与属性名称相同）。
  - Include-指定属性参数`%JSONINCLUDE`（有效值为“inout”（默认值）、“outputly”、“inputOnly”或“none”）。
  - Mapping-要应用于对象属性的映射定义的名称。
  - Null-重写类参数`%JSONNULL`。
  - IgnoreNull-重写类参数`%JSONIGNORENNULL`。
  - Reference-重写类参数`%JSONREFERENCE`。



## 6.4 格式化JSON

`%JSON.Formatter`是一个具有非常简单的接口的类，它允许您将动态对象和数组以及JSON字符串格式化为更易于阅读的表示形式。所有方法都是实例方法，因此您总是从检索实例开始：

```java
  set formatter = ##class(%JSON.Formatter).%New()
```

这种选择背后的原因是，您可以将格式化程序配置为将某些字符用于行终止符和缩进一次（例如，空格与制表符；请参阅本节末尾的属性列表），然后在需要的地方使用它。

`Format()`方法采用动态实体或JSON字符串。下面是一个使用动态对象的简单示例：

```java
  dynObj = {"type":"string"}
  do formatter.Format(dynObj)

```

生成的格式化字符串显示在当前设备上：

```java
  {
    "type":"string"
  }
```

格式方法可以将输出定向到当前设备、字符串或流：

- `Format()`使用指定的缩进来格式化JSON文档，并将其写入当前设备。
- `FormatToStream()`使用指定的缩进格式化JSON文档并将其写入流。
- `FormatToString()`使用指定的缩进格式化JSON文档并将其写入字符串，或者将启用JSON的类序列化为JSON文档并以字符串形式返回。

此外，以下属性可用于控制缩进和换行：

- `Indent`指定JSON输出是否应缩进。
- `IndentChars`指定用于每个缩进级别的字符序列（默认为每个级别一个空格）。
- `LineTerminator`指定缩进时要终止每行的字符序列。



# 7 %JSON适配器快速参考

本章提供了%JSON适配器方法、属性和参数的快速参考。本章涵盖以下主题：

- %JSON.Adaptor方法
- %JSON.Adaptor类和属性参数
- %JSON.Formatter方法和属性



## 7.1 %JSON.Adaptor方法

这些方法提供了从JSON序列化和从JSON序列化到JSON的能力。有关更多信息和示例，请参阅“导出和导入”。

### `%JSONExport()`

`%JSON.Adaptor.%JSONExport()`将启用JSON的类序列化为JSON文档，并将其写入当前设备。

```java
   method %JSONExport(%mappingName As %String = "") as %Status
```

参数：

- `%mappingName`（可选）-用于导出的映射的名称。基本映射由""表示，是默认值。

### `%JSONExportToStream()`

`%JSON.Adaptor.%JSONExportToStream()`将启用JSON的类序列化为JSON文档并将其写入流。

```java
   method %JSONExportToStream(ByRef export As %Stream.Object, 
      %mappingName As %String = "") as %Status
```

参数：

- export-包含序列化JSON文档的流。
- `%mappingName`（可选）-用于导出的映射的名称。基本映射由""表示，是默认值。

### `%JSONExportToString()`

`%JSON.Adaptor.%JSONExportToString()`将启用JSON的类序列化为JSON文档，并将其作为字符串返回。

```java
   method %JSONExportToString(ByRef %export As %String, 
      %mappingName As %String = "") as %Status
```

参数：

- export-包含序列化JSON文档的流。
- `%mappingName`（可选）-用于导出的映射的名称。基本映射由""表示，是默认值。

### `%JSONImport()`

`%JSON.Adaptor.%JSONImport()`将JSON或动态实体输入导入此对象。

```java
   method %JSONImport(input, %mappingName As %String = "") as %Status
```

参数：

- input-JSON作为字符串或流，或`%DynamicAbstractObject`的子类。
- `%mappingName`（可选）-用于导出的映射的名称。基本映射由""表示，是默认值。

### `%JSONNew()`

`%JSON.Adaptor.%JSONNew()`获取启用JSON的类的实例。在返回此类的实例之前，可以重写此方法以执行自定义处理（例如初始化对象实例）。但是，不应直接从用户代码调用此方法。

```java
   classmethod %JSONNew(dynamicObject As %DynamicObject, 
      containerOref As %RegisteredObject = "") as %RegisteredObject
```

- dynamicObject-具有要分配给新对象的值的动态实体。
- containerOref（可选）-从`%JSONImport()`调用时的包含对象实例。



## 7.2 %JSON.Adaptor类和属性参数

除非另有说明，否则可以为类或单个属性指定参数。作为类参数，它指定相应属性参数的默认值。作为属性参数，它指定一个替代默认值的值。有关更多信息和示例，请参阅“使用参数映射”。

### `%JSONENABLED`

启用属性转换方法的生成。

```java
  parameter %JSONENABLED = 1;
```

有效值为：

- 1-（默认）将生成JSON启用方法。
- 0-方法生成器不会生成可运行的方法。

### `%JSONFIELDNAME`（仅限属性）

设置要用作JSON内容中的字段名的字符串。

```java
  parameter %JSONFIELDNAME
```

默认情况下，使用属性名称。

### `%JSONIGNOREINVALIDFIELD`

控制JSON输入中意外字段的处理。

```java
  parameter %JSONIGNOREINVALIDFIELD = 0;
```

有效值为：

- 1-（默认值）将意外字段视为错误。
- 0-将忽略意外的字段。

### `%JSONIGNORENULL`

指定如何存储字符串属性的空字符串。此参数仅适用于真字符串（由`XSDTYPE="string"和`JSONTYPE="string"`确定）。

```java
  parameter %JSONIGNORENULL = 0;
```

有效值为：

- 0-JSON输入中的空字符串（默认值）存储为`$char(0)`，`$char(1)`作为字符串""写入JSON。JSON输入中缺少的字段始终存储为""，""始终根据`%JSONNULL`参数输出为JSON。
- 1-空字符串和缺少的JSON字段都作为""输入，""和$char（0）都作为字段值""输出。

### `%JSONINCLUDE`（仅限属性）

指定此属性是包含在JSON输出还是输入中。

```java
  parameter %JSONINCLUDE = "inout"
```

有效值为：

- “inout”（默认值）-包含在输入和输出中。
- “outputly”-忽略属性作为输入。
- “inputOnly”-忽略作为输出的属性。
- “none”-从不包含属性。

### `%JSONNULL`

控制未指定属性的处理。

```java
  parameter %JSONNULL = 0;
```

有效值为：

- 0-（默认值）导出期间跳过与未指定属性对应的字段。
- 1-未指定的属性将导出为空值。

### `%JSONREFERENCE`

指定如何将对象引用投影到JSON字段。

```java
  parameter %JSONREFERENCE = "OBJECT";
```

有效值为：

- “OBJECT”-（默认）被引用类的属性用于表示被引用对象。
- “ID”-持久类或串行类的ID用于表示引用。
- “OID”-持久类或串行类的OID用于表示引用。oid以类名id的形式投影到JSON。
- “GUID”-持久类的GUID用于表示引用。



## 7.3 %JSON.Formatter方法和属性

`%JSON.Formater`可用于格式化JSON字符串、流或`%DynamicAbstractObject`子类的对象。有关更多信息和示例，请参阅“格式化JSON”一节。

### `Format()`

`%JSON.Formatter.Format()`使用指定的缩进来格式化JSON文档，并将其写入当前设备。

```java
method FormatToStream(input, ByRef export As %Stream.Object) as %Status
```

参数：

- input-JSON作为字符串或流，或`%DynamicAbstractObject`的子类。

### `FormatToStream()`

`%JSON.Formatter.FormatToStream()`使用指定的缩进格式化JSON文档并将其写入流。

```java
method FormatToStream(input, ByRef export As %Stream.Object) as %Status
```

参数：

- input-JSON作为字符串或流，或`%DynamicAbstractObject`的子类。
- export-格式化的JSON流。

### `FormatToString()`

`%JSON.Formatter.FormatToString()`使用指定的缩进设置JSON文档的格式并将其写入字符串，或者将启用JSON的类序列化为JSON文档并将其作为字符串返回。

```java
method FormatToString(input, ByRef export As %String = "") as %Status
```

参数：

- input-JSON作为字符串或流，或`%DynamicAbstractObject`的子类。
- export（可选）-格式化的JSON流。

### `Indent`

`%JSON.Formatter.Indent`属性指定JSON输出是否应缩进。默认为true。

```java
property Indent as %Boolean [ InitialExpression = 1 ];
```

### `IndentChars`

`%JSON.Formatter.IndentChars`属性指定在启用缩进时用于每个缩进级别的字符序列。默认值为一个空格。

```java
property IndentChars as %String [ InitialExpression = " " ];
```

### `LineTerminator`

`%JSON.Formatter.LineTerminator`属性指定缩进时要终止每行的字符序列。默认值为$char(13,10)。

```java
property LineTerminator as %String [ InitialExpression = $char(13,10) ];
```



# 附：JSON使用示例

- `notes.json`

```java
Class notes.json Extends (%RegisteredObject, %JSON.Adaptor)
{

/// Using Object
ClassMethod JSONObject()
{
	/* 创建动态实例 */
	s person = {} //s person = ##class(%DynamicObject).%New()
	s person.Relationships = [] //s person.Relationships = ##class(%DynamicArray).%New()

	s person.IDNum = "342622199304055257" //d person.%Set("IDNum", "342622199304055257")
	s person.Name = "wanyh" 

	s Relationship = {}
    s Relationship.Relation = "father"
    s Relationship.Name = "wanxw"
	d person.Relationships.%Push(Relationship)
	
	s Relationship = {}
    s Relationship.Relation = "mother"
    s Relationship.Name = "tonggx"
	d person.Relationships.%Push(Relationship)

	/* 动态实例转为JSON字符串 */
	s jsonPerson = person.%ToJSON()
	w jsonPerson,!
	s jsonPersonStream = ##class(%Stream.GlobalCharacter).%New()
	d person.%ToJSON(jsonPersonStream)
	#; {"Relationships":[{"Relation":"father","Name":"wanxw"},{"Relation":"mother","Name":"tonggx"}],"IDNum":"342622199304055257","Name":"wanyh"}
	
	/* JSON字符串转为动态实例 */
	s person = {}.%FromJSON(jsonPerson)
	zw person
	s person = {}.%FromJSON(jsonPersonStream.ReadLineIntoStream())
	#; person={"Relationships":[{"Relation":"father","Name":"wanxw"},{"Relation":"mother","Name":"tonggx"}],"IDNum":"342622199304055257","Name":"wanyh"}  ; <DYNAMIC OBJECT>
	
	/* 解析动态实例 */
	w "IDNum:"_person.IDNum,! //w "IDNum:"_person.%Get("IDNum"),!
	w "Name:"_person.Name,!
	
	s itr = person.Relationships.%GetIterator()
	while itr.%GetNext(.key, .val){
		w "Relation:"_val.Relation,!
		w "Name:"_val."Name",!
	}
	#; IDNum:342622199304055257
	#; Name:wanyh
	#; Relation:father
	#; Name:wanxw
	#; Relation:mother
	#; Name:tonggx
}

/// %JSON.Adaptor
ClassMethod JSONAdaptor()
{
	/* 创建对象 */
	s person = ##class(model.Person).%New()
	s person.IDCard = "342622199304055257"
	s person.Name = "wanyh"
	
	s Relationship = ##class(model.Relationship).%New()
	s Relationship.Relation = "father"
	s Relationship.Name = "wanxw"
	d person.Relationships.Insert(Relationship)

	s Relationship = ##class(model.Relationship).%New()
	s Relationship.Relation = "mother"
	s Relationship.Name = "tonggx"
	d person.Relationships.Insert(Relationship)
	
	/* 对象导出为JSON字符串 */
	d person.%JSONExportToString(.jsonPerson)
	w jsonPerson,!
	d person.%JSONExportToStream(.jsonStreamPerson)
	#; {"IDNum":"342622199304055257","Name":"wanyh","Relationships":[{"Relation":"father","Name":"wanxw"},{"Relation":"mother","Name":"tonggx"}]}
	
	/* JSON字符串导入对象 */
	s person = ##class(model.Person).%New()
	d person.%JSONImport(jsonPerson)
	
	/* 解析JSON对象 */ 
	w "IDNum:"_person.IDCard,!
	w "Name:"_person.Name,!

	while person.Relationships.GetNext(.key){
		w "Relation:"_person.Relationships.GetAt(key).Relation,!
		w "Name:"_person.Relationships.GetAt(key).Name,! 
	}
	
	#; IDNum:342622199304055257
	#; Name:wanyh
	#; Relation:father
	#; Name:wanxw
	#; Relation:mother
	#; Name:tonggx
}

}
```

- `model.Person`

```java
Class model.Person Extends (%RegisteredObject, %JSON.Adaptor)
{

/// Person's IDCard number.
Property IDCard As %String(%JSONFIELDNAME = "IDNum", PATTERN = "18N") [ Required ];

/// Name of the person.
Property Name As %String;

/// Person's Relationships.
Property Relationships As list Of model.Relationship;

}
```

- `model.Relationship`

```java
Class model.Relationship Extends (%RegisteredObject, %JSON.Adaptor)
{

/// Relation description.
Property Relation As %String;

/// Name of the person.
Property Name As %String;

}
```



