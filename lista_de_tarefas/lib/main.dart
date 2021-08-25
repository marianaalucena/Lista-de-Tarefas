import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();

  //lista que armazenara as tarefas
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  //mantendo os dados salvos mesmo apos fechar o app
  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    //para mostrar o item na tela apos inserir nova tarefa
    setState(() {
      //json: dynamic
      Map<String, dynamic> newToDo = Map();
      //pega o texto do textField
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      //adicionando o elemento
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  //async porque nao ocorre instantaneamente
  Future<Null> _refresh() async{
    //delay para o carregamento de outras tarefas
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if(a["ok"]  && !b["ok"]) return 1;
        else if(!a["ok"]  && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text("Lista de Tarefas"),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          //Container: para dar os espaçamentos necessarios
          Container(
            padding: EdgeInsets.fromLTRB(17, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                //Expande o textField o maximo que der),
                Expanded(
                    child: TextField(
                  controller: _toDoController,
                  decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                )),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
                //    FlatButton(onPressed: onPressed, child: child)
              ],
            ),
          ),
          //Expanded porque nao sabemos qual o exato tamanho da lista
          Expanded(
            //atualizacao da pagina e ordenacao dos itens
            child: RefreshIndicator(
              onRefresh: _refresh,
              //builder construtor que permite a construcao a partir da rolagem do app, economiza recursos
              child:  ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  //cada item da lista chama o buildItem
  Widget buildItem(context, index) {
    //Dismissible permite arrastar o widget para a direita para deleta-lo
    return Dismissible(
      //Pegando a hora atual em mili segundos e transformando em string
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        //Align para que a lixeira fique no canto esquerdo e nao centralizado
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      //DismissDirection.startToEnd: da esquerda para direita
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        //index elemento da lista que esta sendo desenhado no momento
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      //para remover um item e depois desfazer a acao
      onDismissed: (direction) {
        setState(() {
          //duplica o dado a ser removido
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            //conteudo da snackBar
            content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            //açao da snackbar
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
               setState(() {
                 //incluido a tarefa novamente na lista
                 _toDoList.insert(_lastRemovedPos, _lastRemoved);
                 _saveData();
               });
              },
            ),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  //arquivo que salvara os dados
  Future<File> _getFile() async {
    //essa funcao pega o diretorio onde serao armazenados os dados do app
    //usa-se await devido a funcao retornar um Future
    final directory = await getApplicationDocumentsDirectory();
    //${directory.path} pega o caminho do diretorio
    return File("${directory.path}/data.json");
  }

//funcao que salvara os dados
  Future<File> _saveData() async {
    //transformando a lista em json
    String data = json.encode(_toDoList);
    final file = await _getFile();
    //pega o arquivo e escreve os dados da lista - salva os dados como string
    return file.writeAsString(data);
  }

  //funcao para obter os dados
  Future<String> _readData() async {
    try {
      final file = await _getFile();
      //tenta ler os dados como string
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
