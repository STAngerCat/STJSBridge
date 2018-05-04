/**
 * @file JSBridge
 * @author Duran<yinheng01@baidu.com>
 */
declare namespace STJSBridge {
    /**
     * 普通回调
     *
     * @type {any} 可选回调参数
     */
    type BaseCallBack = (content?: any) => void;
    /**
     * 带参数和回调的回调
     *
     * @type {any} content 回调参数
     * @type {BaseCallBack} complete 针对回调消息本身的普通回调
     */
    type MessageCallBack = (content?: any, complete?: BaseCallBack) => void;
    /**
     * 向客户端发送消息
     *
     * @param {string} name 消息名字
     * @param {any} content 附带参数
     * @param {BaseCallBack} complete 处理了来自客户端的回调
     */
    function sendMessage(name: string, content: any, complete: BaseCallBack): void;
    /**
     * 监听来自客户端的消息
     *
     * @param {string} name 监听的消息名
     * @param {MessageCallBack} handler 处理消息
     */
    function addEventListener(name: string, handler: MessageCallBack): void;
}
