import {NativeModules} from 'react-native';
import type { Double } from 'react-native/Libraries/Types/CodegenTypes';

export interface DocumentsHandlerRequest {
  documents: string[];
  grayscale: true;
  expectedWidth: Double;
}

export interface DocumentsHandlerResult {
  request: string;//DocumentsHandlerRequest;
  distance: string;//number;
  status: string;//'moving' | 'delivered';
}

export interface DocumentsHandler {
  process: (request: DocumentsHandlerRequest) => Promise<DocumentsHandlerResult>;
}

export default NativeModules.RNDocumentsHandler as DocumentsHandler;
