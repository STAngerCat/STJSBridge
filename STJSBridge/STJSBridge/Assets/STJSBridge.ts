namespace STJSBridge {
	/**
	 * 普通回调
	 * @type {any} 可选回调参数
	 */
	export type BaseCallBack = (content?:any)=>void;

	/**
	 * 带参数和回调的回调
	 * @type {any} 回调参数
	 * @type {BaseCallBack} 针对回调消息本身的普通回调
	 */
	export type MessageCallBack = (content?:any,complete?:BaseCallBack)=>void;

    /**
     * 消息模型
     */
	class STMessage {
		/**
		 * 消息发送 ID
		 * @type {number}
		 */
		requestId:number = 0;
		/**
		 * 返回消息 ID
		 * @type {number}
		 */
		responseId?:number;
		/**
		 * 消息名
		 * @type {string}
		 */
		name?:string;
		/**
		 * 消息所带内容
		 * @type {any}
		 */
		content?:any;

		constructor(data?:any) {
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
		JSONString():string {
			let dic:{[key:string]:any} = {};
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
		}
	}

	/**
	 * 对消息处理
	 */
	class STMessageMananger {

		private eventMap:{[key:string]:[MessageCallBack]} = {};
		private noneNameEventHandler:MessageCallBack = ()=>{};
		private callBackList:{[key:number]:BaseCallBack} = {};

		private requestId = 0;

		formWebToClient(name?:string, content?:any, complete?:BaseCallBack) {
			let message = new STMessage();
			message.requestId = ++this.requestId;
			message.name = name;
			message.content = content;

			if (complete) {
				this.callBackList[message.requestId] = complete;
			}

			this.sendMessage(message);
		}

		formClientToWeb(data:any) {
			let message = new STMessage(data)
			let name = message.name;

			if (message.responseId) {
				if (message.responseId in this.callBackList) {
					let callback = this.callBackList[message.responseId];
					callback(message.content);
					delete this.callBackList[message.responseId];
				}
			} else if (name in this.eventMap) {
				this.eventMap[name].forEach((item)=>{
					item(message.content,(content)=>{
						this.responseToMessage(message,content);
					});
				})
			} else if (this.noneNameEventHandler) {
				this.noneNameEventHandler(message.content,(content)=>{
					this.responseToMessage(message,content);
				})
			}
		}

		addEventListener(handler:MessageCallBack, name?:string) {
			if (name) {
				if (name in this.eventMap) {
					this.eventMap[name].push(handler);
				} else {
					this.eventMap[name] = [handler];
				}
			} else {
				this.noneNameEventHandler = handler;
			}
		}


		private responseToMessage(message:STMessage,content?:any) {
			let responseMessage = new STMessage();
			responseMessage.responseId = message.requestId;
			responseMessage.content = content;
			this.sendMessage(responseMessage);
		}

		private sendMessage(message:STMessage) {
			let data = message.JSONString()
			if (window["__inject__web__message__send__"]) {
				window["__inject__web__message__send__"](data)
			} else if (window['webkit'] && window['webkit'].messageHandlers[window["__inject__web__message__send__key__"]]) {
				window['webkit'].messageHandlers[window["__inject__web__message__send__key__"]].postMessage(data);
			} else {
				console.warn('Client has no Message Handler')
			}
		}
	}


	const messageManager = new STMessageMananger();
	/**
	 * @param {string} 消息名字
	 * @param {any} 附带参数
	 * @param {BaseCallBack} 处理了来自客户端的回调
	 */
	export function sendMessage(name:string, content:any, complete:BaseCallBack):void {
		messageManager.formWebToClient(name,content,complete);
	}

	/**
	 * @param {string} 监听的消息名
	 * @param {MessageCallBack} 处理消息
	 */
	export function addEventListener(name:string ,handler:MessageCallBack):void {
		messageManager.addEventListener(handler,name);			
	}


	window["__inject__native_message__send__"] = (data)=>{
		messageManager.formClientToWeb(data)
	};

	window.dispatchEvent(new Event("JSBridgeReady"));
}