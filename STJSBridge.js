// JSBridge
var STJSBridge;
(function (STJSBridge) {
    const __inject__web__message__send__key__ = "###replace_message_key###"; // 客户端会替换这里的值
    /**
     * 消息模型
     */
    class STMessage {
        constructor(data) {
            /**
             * 消息发送 ID
             *
             * @type {number}
             */
            this.requestId = 0;
            if (data) {
                this.responseId = data['responseId'];
                this.name = data['name'];
                this.content = data['content'];
                this.requestId = data['requestId'];
                this.error = data['error'];
            }
        }
        /**
         * 返回序列化的数据
         *
         * @return {object}
         */
        json() {
            let dic = {};
            dic['requestId'] = this.requestId;
            if (this.responseId) {
                dic['responseId'] = this.responseId;
            }
            if (this.name) {
                dic['name'] = this.name;
            }
            if (this.content) {
                dic['content'] = this.content;
            }
            if (this.error) {
                dic['error'] = this.error;
            }
            return dic;
        }
    }
    /**
     * 对消息处理
     *
     */
    class STMessageMananger {
        constructor() {
            this.eventMap = {};
            this.noneNameEventHandler = () => { };
            this.callBackList = {};
            this.requestId = 0;
        }
        formWebToClient(name, content, complete) {
            let message = new STMessage();
            message.requestId = ++this.requestId;
            message.name = name;
            message.content = content;
            if (complete) {
                this.callBackList[message.requestId] = complete;
            }
            this.sendMessage(message);
        }
        formClientToWeb(data) {
            let message = new STMessage(data);
            let name = message.name;
            if (message.responseId) {
                if (message.responseId in this.callBackList) {
                    let callback = this.callBackList[message.responseId];
                    callback(message.content, message.error);
                    delete this.callBackList[message.responseId];
                }
            }
            else if (name in this.eventMap) {
                this.eventMap[name].forEach(item => {
                    item(message.content, (content, error) => {
                        this.responseToMessage(message.requestId, content, error);
                    });
                });
            }
            else if (this.noneNameEventHandler) {
                this.noneNameEventHandler(message.content, (content, error) => {
                    this.responseToMessage(message.requestId, content, error);
                });
            }
        }
        addEventListener(handler, name) {
            if (name) {
                if (name in this.eventMap) {
                    this.eventMap[name].push(handler);
                }
                else {
                    this.eventMap[name] = [handler];
                }
            }
            else {
                this.noneNameEventHandler = handler;
            }
        }
        removeEventListener(name) {
            if (name in this.eventMap) {
                delete this.eventMap[name];
            }
        }
        responseToMessage(messageId, content, error) {
            let responseMessage = new STMessage();
            responseMessage.responseId = messageId;
            responseMessage.content = content;
            responseMessage.error = error;
            this.sendMessage(responseMessage);
        }
        sendMessage(message) {
            let data = message.json();
            if (window['webkit'] && window['webkit'].messageHandlers[__inject__web__message__send__key__]) {
                window['webkit'].messageHandlers[__inject__web__message__send__key__].postMessage(data);
            }
            else {
                console.warn('Client has no Message Handler');
            }
        }
    }
    const messageManager = new STMessageMananger();
    function sendMessage() {
        let name = arguments[0];
        if (typeof name != "string") {
            throw "`name` should be string";
        }
        let content = undefined;
        let complete = undefined;
        if (typeof arguments[1] == 'function') {
            complete = arguments[1];
        }
        else {
            content = arguments[1];
        }
        if (typeof arguments[2] == 'function') {
            complete = arguments[2];
        }
        messageManager.formWebToClient(name, content, complete);
    }
    STJSBridge.sendMessage = sendMessage;
    /**
     * 监听来自客户端的消息
     *
     * @param {string} name 监听的消息名
     * @param {MessageCallBack} handler 处理消息
     */
    function addEventListener(name, handler) {
        messageManager.addEventListener(handler, name);
    }
    STJSBridge.addEventListener = addEventListener;
    /**
     * 移除对客户端的消息监听
     * @param {string} name 监听的消息名
     */
    function removeEventListener(name) {
        messageManager.removeEventListener(name);
    }
    STJSBridge.removeEventListener = removeEventListener;
    window['__inject__native_message__send__'] = data => {
        messageManager.formClientToWeb(data);
    };
})(STJSBridge || (STJSBridge = {}));
