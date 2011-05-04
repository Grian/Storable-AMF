loader = new URLLoader();
loader.addEventListener(Event.COMPLETE, onLoadData);
loader.dataFormat=URLLoaderDataFormat.BINARY;
loader.load(new URLRequest(url));

private function onLoadData( e : Event ) : void {
    var l : URLLoader = URLLoader( e.target );
    var data: ByteArray  = l.data;
    data.objectEncoding = ObjectEncoding.AMF3; // Or ObjectEncoding.AMF0
    var resultObject =   data.ReadObject();    // resultObject = { greeting : "Hello from ... !!!" }
}
