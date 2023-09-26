import {NativeModules} from 'react-native';
import type { Double, Float } from 'react-native/Libraries/Types/CodegenTypes';

export interface DocumentsHandlerRequest {
  documents: string[];
  grayscale: true;
  expectedWidth: Float;
}

export interface DocumentsHandlerResult {
  documents: string[];
}

export interface DocumentsHandler {
  process: (request: DocumentsHandlerRequest) => Promise<DocumentsHandlerResult>;
}

export default NativeModules.RNDocumentsHandler as DocumentsHandler;
