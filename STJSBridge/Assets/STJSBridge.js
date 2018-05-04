/**
 * @file JSBridge
 * @author Duran<yinheng01@baidu.com>
 */
let STJSBridge;
(function (STJSBridge) {

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
                this.responseId = data.responseId;
                this.name = data.name;
                this.content = data.content;
                this.requestId = data.requestId;
            }
        }

        /**
         * 返回序列化的数据
         *
         * @return {string}
         */
        jsonString() {
            let dic = {};
            dic.requestId = this.requestId;
            if (this.responseId) {
                dic.responseId = this.responseId;
            }

            if (this.name) {
                dic.name = this.name;
            }

            if (this.content) {
                dic.content = this.content;
            }

            return JSON.stringify(dic);
        }
    }

    /**
     * 对消息处理
     *
     */
    class STMessageMananger {
        constructor() {
            this.eventMap = {};
            this.noneNameEventHandler = () => {
            };
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
                    callback(message.content);
                    delete this.callBackList[message.responseId];
                }
            }
            else if (name in this.eventMap) {
                this.eventMap[name].forEach(item => {
                    item(message.content, content => {
                        this.responseToMessage(message, content);
                    });
                });
            }
            else if (this.noneNameEventHandler) {
                this.noneNameEventHandler(message.content, content => {
                    this.responseToMessage(message, content);
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
        responseToMessage(message, content) {
            let responseMessage = new STMessage();
            responseMessage.responseId = message.requestId;
            responseMessage.content = content;
            this.sendMessage(responseMessage);
        }
        sendMessage(message) {
            let data = message.jsonString();
            if (window['__inject__web__message__send__']) {
                window['__inject__web__message__send__'](data);
            }
            else if (window.webkit && window.webkit.messageHandlers[window['__inject__web__message__send__key__']]) {
                window.webkit.messageHandlers[window['__inject__web__message__send__key__']].postMessage(data);
            }
            else {
                console.warn('Client has no Message Handler');
            }
        }
    }
    const messageManager = new STMessageMananger();

    /**
     * 向客户端发送消息
     *
     * @param {string} name 消息名字
     * @param {any} content 附带参数
     * @param {BaseCallBack} complete 处理了来自客户端的回调
     */
    function sendMessage(name, content, complete) {
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
    window['__inject__native_message__send__'] = data => {
        messageManager.formClientToWeb(data);
    };
    window.dispatchEvent(new Event('JSBridgeReady'));
})(STJSBridge || (STJSBridge = {}));
