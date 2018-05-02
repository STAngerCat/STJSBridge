var STJSBridge;
(function (STJSBridge) {
    /**
     * 消息模型
     */
    var STMessage = /** @class */ (function () {
        function STMessage(data) {
            /**
             * 消息发送 ID
             * @type {number}
             */
            this.requestId = 0;
            if (data) {
                this.responseId = data['responseId'];
                this.name = data['name'];
                this.content = data['content'];
                this.requestId = data['requestId'];
            }
        }
        /**
         * 返回序列化的数据
         * @return {string}
         */
        STMessage.prototype.JSONString = function () {
            var dic = {};
            dic["requestId"] = this.requestId;
            if (this.responseId) {
                dic['responseId'] = this.responseId;
            }
            if (this.name) {
                dic['name'] = this.name;
            }
            if (this.content) {
                dic['content'] = this.content;
            }
            return JSON.stringify(dic);
        };
        return STMessage;
    }());
    /**
     * 对消息处理
     */
    var STMessageMananger = /** @class */ (function () {
        function STMessageMananger() {
            this.eventMap = {};
            this.noneNameEventHandler = function () { };
            this.callBackList = {};
            this.requestId = 0;
        }
        STMessageMananger.prototype.formWebToClient = function (name, content, complete) {
            var message = new STMessage();
            message.requestId = ++this.requestId;
            message.name = name;
            message.content = content;
            if (complete) {
                this.callBackList[message.requestId] = complete;
            }
            this.sendMessage(message);
        };
        STMessageMananger.prototype.formClientToWeb = function (data) {
            var _this = this;
            var message = new STMessage(data);
            var name = message.name;
            if (message.responseId) {
                if (message.responseId in this.callBackList) {
                    var callback = this.callBackList[message.responseId];
                    callback(message.content);
                    delete this.callBackList[message.responseId];
                }
            }
            else if (name in this.eventMap) {
                this.eventMap[name].forEach(function (item) {
                    item(message.content, function (content) {
                        _this.responseToMessage(message, content);
                    });
                });
            }
            else if (this.noneNameEventHandler) {
                this.noneNameEventHandler(message.content, function (content) {
                    _this.responseToMessage(message, content);
                });
            }
        };
        STMessageMananger.prototype.addEventListener = function (handler, name) {
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
        };
        STMessageMananger.prototype.responseToMessage = function (message, content) {
            var responseMessage = new STMessage();
            responseMessage.responseId = message.requestId;
            responseMessage.content = content;
            this.sendMessage(responseMessage);
        };
        STMessageMananger.prototype.sendMessage = function (message) {
            var data = message.JSONString();
            if (window["__inject__web__message__send__"]) {
                window["__inject__web__message__send__"](data);
            }
            else if (window['webkit'] && window['webkit'].messageHandlers[window["__inject__web__message__send__key__"]]) {
                window['webkit'].messageHandlers[window["__inject__web__message__send__key__"]].postMessage(data);
            }
            else {
                console.warn('Client has no Message Handler');
            }
        };
        return STMessageMananger;
    }());
    var messageManager = new STMessageMananger();
    /**
     * @param {string} 消息名字
     * @param {any} 附带参数
     * @param {BaseCallBack} 处理了来自客户端的回调
     */
    function sendMessage(name, content, complete) {
        messageManager.formWebToClient(name, content, complete);
    }
    STJSBridge.sendMessage = sendMessage;
    /**
     * @param {string} 监听的消息名
     * @param {MessageCallBack} 处理消息
     */
    function addEventListener(name, handler) {
        messageManager.addEventListener(handler, name);
    }
    STJSBridge.addEventListener = addEventListener;
    window["__inject__native_message__send__"] = function (data) {
        messageManager.formClientToWeb(data);
    };
    window.dispatchEvent(new Event("JSBridgeReady"));
})(STJSBridge || (STJSBridge = {}));
