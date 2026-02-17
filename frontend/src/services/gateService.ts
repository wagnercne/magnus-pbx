import api from './api';

export interface GateLog {
  id: number;
  tenantId: number;
  extension: string;
  action: 'opened' | 'denied' | 'attempted';
  openedAt: string;
  ipAddress?: string;
}

export interface OpenGateResponse {
  success: boolean;
  message: string;
  logId?: number;
}

export interface GetLogsParams {
  page?: number;
  pageSize?: number;
  startDate?: string;
  endDate?: string;
}

export interface GetLogsResponse {
  logs: GateLog[];
  totalCount: number;
  page: number;
  pageSize: number;
}

/**
 * Serviço para controle de portões
 */
export const gateService = {
  /**
   * Abre o portão (requer permissão)
   */
  async openGate(): Promise<OpenGateResponse> {
    const response = await api.post<OpenGateResponse>('/gates/open');
    return response.data;
  },

  /**
   * Busca logs de abertura do portão com paginação
   */
  async getLogs(params: GetLogsParams = {}): Promise<GetLogsResponse> {
    const response = await api.get<GetLogsResponse>('/gates/logs', { params });
    return response.data;
  },

  /**
   * Busca logs em tempo real (últimos 10)
   */
  async getRecentLogs(): Promise<GateLog[]> {
    const response = await this.getLogs({ page: 1, pageSize: 10 });
    return response.logs;
  }
};
