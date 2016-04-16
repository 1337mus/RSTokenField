# RSTokenField

RSTokenField is a drop in tokenfield replacement which provides Mail tokenfield like features.
- Create Tokens or insert bare strings
- Modular and light weight design

##Important Classes
- **RSTokenTextView** (Subclass of NSTextView) - This is the powerhouse behind all the text operations. Relies on a struct called RSTokenPosition which contains
new range and old range information to perform any manipulation to the text entered
- **RSTokenField** (Subclass of NSTextField) - This is the textfield that declares RSTokenTextView as its field editor
- **RSTokeView** (Subclass of plain old NSView)- This is the token representation view which has a similar look and feel as the Mail app search tokens. If you need custom look you will 
have to override/replace this class with your own representation. (Through a xib file)

![RSTokenField](https://raw.githubusercontent.com/1337mus/RSTokenField/master/docs/RSTokenField.png)



