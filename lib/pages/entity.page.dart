part of '../main.dart';

class EntityViewPage extends StatefulWidget {
  EntityViewPage({Key key, @required this.entityId}) : super(key: key);

  final String entityId;

  @override
  _EntityViewPageState createState() => new _EntityViewPageState();
}

class _EntityViewPageState extends State<EntityViewPage> {
  StreamSubscription _refreshDataSubscription;
  StreamSubscription _stateSubscription;
  Entity entity;
  Entity forwardToMainPage;
  bool _popScheduled = false;

  @override
  void initState() {
    super.initState();
    _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
      if (event.entityId == widget.entityId) {
        entity = HomeAssistant().entities.get(widget.entityId);
        Logger.d("[Entity page] State change event handled: ${event.entityId}");
        setState(() {});
      }
    });
    _refreshDataSubscription = eventBus.on<RefreshDataFinishedEvent>().listen((event) {
      entity = HomeAssistant().entities.get(widget.entityId);
      setState(() {});
    });
    entity = HomeAssistant().entities.get(widget.entityId);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (MediaQuery.of(context).size.width >= Sizes.tabletMinWidth) {
      if (!_popScheduled) {
        _popScheduled = true;
        _popAfterBuild();
      }
      body = PageLoadingIndicator();
    } else {
      body = EntityPageLayout(entity: entity);
    }
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          Navigator.pop(context);
        }),
        title: new Text("${entity.displayName}"),
      ),
      body: body,
    );
  }

  _popAfterBuild() async {
    forwardToMainPage = entity;
    await Future.delayed(Duration(milliseconds: 300));
    Navigator.of(context).pop();
  }

  @override
  void dispose(){
    if (_stateSubscription != null) _stateSubscription.cancel();
    if (_refreshDataSubscription != null) _refreshDataSubscription.cancel();
    eventBus.fire(ShowEntityPageEvent(entity: forwardToMainPage));
    super.dispose();
  }
}