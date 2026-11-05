// Copyright (c) 2026 Vector Stream Systems LLC. All rights reserved.
// SPDX-License-Identifier: LicenseRef-Proprietary

package '大型キャブオーバー車インタフェース' {
    doc /*
     * 大型 25 t キャブオーバー単車（自動運転レベル 4）のポートとインタフェース定義。
     * 車両電源は 24 V の二重系、単位はすべて SI（メートル法）。
     */
    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import MBEstudio::*;

    /* ------------------------------------------------------------ */
    /* 24 V 電源                                                     */
    /* ------------------------------------------------------------ */

    port def '24V電源ポート' {
        doc /*
         * 24 V 車両電源ポート（ネット A またはネット B）。current はこのポートの負荷電流、
         * power は消費電力。PDU の eFuse チャネルから各負荷へ配る。
         */
        out attribute voltage : ElectricPotentialValue default 24 [V];
        out attribute current : ElectricCurrentValue default 0 [A];
        out attribute power : PowerValue default 0 [W];
    }

    interface def '24V給電線' {
        doc /* PDU の eFuse チャネル 1 本から負荷 1 台への 24 V 給電線。 */
        end supplier : '24V電源ポート';
        end '負荷' : ~'24V電源ポート';
    }

    /* ------------------------------------------------------------ */
    /* 車載 Ethernet（TSN）                                           */
    /* ------------------------------------------------------------ */

    port def 'Ethernetポート' {
        doc /*
         * 車載 Ethernet 端点（センサ側 1000BASE-T1、バックボーン 10GBASE-T1、TSN 対応）。
         * dataRateMbps は流すデータ量、linkCapacityMbps はポート速度（いずれも Mbit/s）、
         * latency は伝送遅延。
         */
        attribute dataRateMbps : Real default 100.0;
        attribute 'リンク容量Mbps' : Real default 1000.0;
        attribute latency : DurationValue default 0.0005 [s];
    }

    interface def 'Ethernetリンク' {
        doc /* センサ、スイッチ、計算機を結ぶ Ethernet リンク（双方向）。 */
        end '端A' : 'Ethernetポート';
        end '端B' : 'Ethernetポート';
    }

    /* ------------------------------------------------------------ */
    /* CAN FD                                                         */
    /* ------------------------------------------------------------ */

    port def 'CANポート' {
        doc /*
         * CAN FD 端点。調停相 500 kbit/s、データ相 2 Mbit/s。loadFraction はバス負荷率、
         * cycleTime は指令の更新周期。
         */
        attribute 'ビットレート' : Real default 2000000.0;
        attribute '公称ビットレート' : Real default 500000.0;
        attribute '負荷率' : Real default 0.1;
        attribute '周期' : DurationValue default 0.01 [s];
    }

    interface def 'CANリンク' {
        doc /* 計算機、ゲートウェイ、ECU を結ぶ CAN FD 接続。 */
        end '端A' : 'CANポート';
        end '端B' : 'CANポート';
    }

    /* ------------------------------------------------------------ */
    /* 時刻同期（gPTP）                                               */
    /* ------------------------------------------------------------ */

    port def '時刻同期ポート' {
        doc /*
         * gPTP（IEEE 802.1AS）時刻同期ポート。syncInterval は Sync メッセージ周期、
         * offset はグランドマスタに対する許容オフセット。
         */
        attribute '同期間隔' : DurationValue default 0.125 [s];
        attribute offset : DurationValue default 0.0000005 [s];
    }

    interface def '時刻同期リンク' {
        doc /* グランドマスタから時刻同期対象の端点へ。 */
        end 'マスタ' : '時刻同期ポート';
        end 'スレーブ' : ~'時刻同期ポート';
    }

    /* ------------------------------------------------------------ */
    /* 圧縮空気（フルエアブレーキ、エアサスペンション）               */
    /* ------------------------------------------------------------ */

    port def '空気ポート' {
        doc /* 圧縮空気ポート。pressure はゲージ圧、flowLitresPerSecond は流量。 */
        out attribute pressure : PressureValue default 850000 [Pa];
        out attribute '流量Ls' : Real default 5.0;
    }

    interface def 'エア配管' {
        doc /* エアタンクまたはモジュレータからブレーキチャンバ、エアばねへの配管。 */
        end '供給' : '空気ポート';
        end '送出' : ~'空気ポート';
    }

    /* ------------------------------------------------------------ */
    /* 電磁弁駆動                                                     */
    /* ------------------------------------------------------------ */

    port def '弁駆動ポート' {
        doc /* ECU から電空モジュレータのソレノイドへの駆動出力。coilCurrent はコイル電流。 */
        out attribute coilCurrent : ElectricCurrentValue default 1 [A];
        attribute 'チャネル数' : Integer default 3;
    }

    interface def '弁駆動' {
        doc /* ブレーキ ECU の弁駆動段からモジュレータの電磁弁へ。 */
        end '運転者' : '弁駆動ポート';
        end '弁' : ~'弁駆動ポート';
    }

    /* ------------------------------------------------------------ */
    /* 操舵機構                                                       */
    /* ------------------------------------------------------------ */

    port def '操舵トルクポート' {
        doc /* EPS モータまたはステアリングギアの出力トルク（N m）。 */
        out attribute torqueNm : Real default 60.0;
    }

    interface def '操舵駆動' {
        doc /* EPS モータからステアリングギア、ギアからリンク機構への機械的伝達。 */
        end 'モータ' : '操舵トルクポート';
        end 'ステアリングギヤ' : ~'操舵トルクポート';
    }

    port def '相電力ポート' {
        doc /* インバータからモータ巻線 1 組への三相駆動。 */
        out attribute phaseCurrent : ElectricCurrentValue default 60 [A];
    }

    interface def 'モータ相リンク' {
        doc /* インバータの三相出力からモータ巻線へ。 */
        end 'インバータ' : '相電力ポート';
        end '巻線' : ~'相電力ポート';
    }

    port def 'ゲート指令ポート' {
        doc /* 操舵 ECU からインバータへの PWM ゲート指令。pwmFrequencyHz はスイッチング周波数。 */
        out attribute pwmFrequencyHz : Real default 20000.0;
    }

    interface def 'ゲート指令リンク' {
        doc /* 操舵 ECU 1 チャネルから同じ系統のインバータへ。 */
        end '制御器' : 'ゲート指令ポート';
        end 'インバータ' : ~'ゲート指令ポート';
    }

    port def 'センサ信号ポート' {
        doc /* SENT などのディジタルセンサ信号。updatePeriod は更新周期。 */
        out attribute updatePeriod : DurationValue default 0.001 [s];
    }

    interface def 'センサ信号リンク' {
        doc /* センサから ECU への信号線。 */
        end 'センサ部' : 'センサ信号ポート';
        end '受信側' : ~'センサ信号ポート';
    }

    /* ------------------------------------------------------------ */
    /* 動力伝達                                                       */
    /* ------------------------------------------------------------ */

    port def 'トルクポート' {
        doc /* 機械的な動力伝達。torqueNm はトルク、speedRpm は回転数、power は軸動力。 */
        out attribute torqueNm : Real default 2150.0;
        out attribute '回転数rpm' : Real default 1200.0;
        out attribute power : PowerValue default 330 [kW];
    }

    interface def 'ドライブライン' {
        doc /* エンジン、変速機、プロペラシャフト、駆動軸の間の動力伝達。 */
        end '主側' : 'トルクポート';
        end '被駆動側' : ~'トルクポート';
    }

    /* ------------------------------------------------------------ */
    /* 燃料、排気、冷却                                               */
    /* ------------------------------------------------------------ */

    port def '燃料ポート' {
        doc /* 軽油の供給ポート。fuelFlowKgS は流量、pressure はフィードポンプ吐出圧。 */
        out attribute fuelFlowKgS : Real default 0.015;
        out attribute pressure : PressureValue default 500000 [Pa];
    }

    interface def '燃料配管' {
        doc /* 燃料タンクからエンジンの高圧ポンプへ。 */
        end 'タンク部' : '燃料ポート';
        end '給電' : ~'燃料ポート';
    }

    port def '排気ポート' {
        doc /* 排気ガスの流れ。massFlowKgS は排気流量、temperatureC は排気温度。 */
        out attribute massFlowKgS : Real default 0.35;
        out attribute temperatureC : Real default 380.0;
    }

    interface def '排気管路' {
        doc /* エンジン排気マニホールドから後処理装置（DPF、尿素 SCR）へ。 */
        end 'エンジン' : '排気ポート';
        end '後処理' : ~'排気ポート';
    }

    port def '冷却水ポート' {
        doc /* 冷却液ループの接続。流量 L/min と供給温度 C。 */
        out attribute '流量Lmin' : Real default 12.0;
        out attribute '供給温度C' : Real default 35.0;
    }

    interface def '冷却水回路' {
        doc /* 冷却ポンプと熱交換器から計算機のコールドプレートへ。 */
        end source : '冷却水ポート';
        end '受け側' : ~'冷却水ポート';
    }

    port def '油圧ポート' {
        doc /* 油圧ポート（ウイング開閉、キャブチルト）。pressure は作動圧。 */
        out attribute pressure : PressureValue default 14000000 [Pa];
        out attribute '流量Lmin' : Real default 6.0;
    }

    interface def '油圧配管' {
        doc /* 油圧パワーユニットからシリンダへ。 */
        end 'ポンプ' : '油圧ポート';
        end 'アクチュエータ' : ~'油圧ポート';
    }

    /* ------------------------------------------------------------ */
    /* 構造                                                           */
    /* ------------------------------------------------------------ */

    port def '車軸取付ポート' {
        doc /* フレームの懸架装置取付部。axleLoad はその軸がフレームに伝える静的荷重。 */
        in attribute axleLoad : ForceValue default 85000 [N];
    }

    interface def '車軸取付' {
        doc /* 車軸を懸架装置（板ばね、エアばね）でフレームに保持する。 */
        end '構造' : '車軸取付ポート';
        end '車軸' : ~'車軸取付ポート';
    }

    port def 'ボデー取付ポート' {
        doc /* 架装物（荷箱）をフレームに固定する U ボルトと固定金具。verticalLoad は鉛直荷重。 */
        in attribute verticalLoad : ForceValue default 160000 [N];
    }

    interface def 'ボデー取付' {
        doc /* ウイング荷箱の縦根太をシャシーフレームに固定する。 */
        end 'シャシ側' : 'ボデー取付ポート';
        end 'ボデー' : ~'ボデー取付ポート';
    }

    /* ------------------------------------------------------------ */
    /* 遠隔監視と路車間通信                                           */
    /* ------------------------------------------------------------ */

    port def '携帯通信ポート' {
        doc /* 5G の上り回線。uplinkMbps は上り帯域、roundTrip は往復遅延。 */
        attribute 'アップリンクMbps' : Real default 20.0;
        attribute '往復時間' : DurationValue default 0.06 [s];
    }

    interface def '遠隔監視リンク' {
        doc /* 車両の通信装置から遠隔監視センターへ（通信事業者網経由）。 */
        end 'トラック' : '携帯通信ポート';
        end center : '携帯通信ポート';
    }

    port def 'V2Xポート' {
        doc /* 760 MHz 帯 ITS 通信と 5.8 GHz 帯 DSRC（ETC 2.0）の無線ポート。rangeM は通信距離。 */
        attribute '搬送波MHz' : Real default 760.0;
        attribute rangeM : Real default 300.0;
    }
}

package '大型キャブオーバー車部品' {
    doc /* 大型キャブオーバー L4 自動運転トラックの部品とアセンブリ。 */
    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import ShapeItems::*;
    private import MBEstudio::*;
    private import '大型キャブオーバー車インタフェース'::*;

    /* ------------------------------------------------------------ */
    /* 部品：電子部品 */
    /* ------------------------------------------------------------ */

    part def 'マイコン型' {
        doc /* ロックステップ車載マイコン（ASIL D 対応、HSM 内蔵）。 */
        attribute mass :> ISQ::mass default 0.005 [kg];
        attribute '消費電力' : PowerValue default 1.2 [W];
        attribute 'クロックMHz' : Real default 300.0;
        attribute 'ロックステップ' : Boolean default true;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.002 [m]; }
    }

    part def 'CAN_FDトランシーバ' {
        doc /* CAN FD トランシーバ（データ相 5 Mbit/s、バス故障保護付き）。 */
        attribute mass :> ISQ::mass default 0.001 [kg];
        attribute '消費電力' : PowerValue default 0.15 [W];
        attribute '最大データレート' : Real default 5000000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.005 [m]; :>> width = 0.004 [m]; :>> height = 0.001 [m]; }
    }

    part def 'Ethernet_PHY型' {
        doc /* 車載 Ethernet PHY（100BASE-T1 / 1000BASE-T1）。 */
        attribute mass :> ISQ::mass default 0.001 [kg];
        attribute '消費電力' : PowerValue default 0.4 [W];
        attribute 'データレートMbps' : Real default 1000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.008 [m]; :>> width = 0.008 [m]; :>> height = 0.001 [m]; }
    }

    part def '電源管理IC型' {
        doc /* 電源管理 IC：降圧レギュレータ、電圧監視、セーフステート出力。 */
        attribute mass :> ISQ::mass default 0.003 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute efficiency : Real default 0.88;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.01 [m]; :>> height = 0.002 [m]; }
    }

    part def 'フラッシュメモリ' {
        doc /* ブートイメージと適合値を格納するシリアル NOR フラッシュ。 */
        attribute mass :> ISQ::mass default 0.002 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '容量MiB' : Real default 64.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.008 [m]; :>> height = 0.001 [m]; }
    }

    part def 'ウィンドウウォッチドッグ' {
        doc /* SPI 接続の外部ウィンドウウォッチドッグ。早すぎても遅すぎても MCU をリセットする。 */
        attribute mass :> ISQ::mass default 0.001 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute timeout : DurationValue default 0.03 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.004 [m]; :>> width = 0.004 [m]; :>> height = 0.001 [m]; }
    }

    part def '基板温度センサ' {
        doc /* 基板温度センサ（ディレーティング用）。 */
        attribute mass :> ISQ::mass default 0.002 [kg];
        attribute '消費電力' : PowerValue default 0.01 [W];
        attribute '測定上限C' : Real default 150.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.005 [m]; :>> width = 0.005 [m]; :>> height = 0.003 [m]; }
    }

    part def 'ゲートドライバ型' {
        doc /* MOSFET ハーフブリッジまたは弁コイル用の絶縁ゲートドライバ。 */
        attribute mass :> ISQ::mass default 0.002 [kg];
        attribute '消費電力' : PowerValue default 0.3 [W];
        attribute 'チャネル数' : Integer default 2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.008 [m]; :>> width = 0.008 [m]; :>> height = 0.002 [m]; }
    }

    part def 'パワーMOSFET' {
        doc /* 車載パワー MOSFET。powerDraw は定格電流時の導通損失。 */
        attribute mass :> ISQ::mass default 0.004 [kg];
        attribute '消費電力' : PowerValue default 2.0 [W];
        attribute 'オン抵抗mOhm' : Real default 1.2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.01 [m]; :>> height = 0.002 [m]; }
    }

    part def '電流シャント' {
        doc /* 相電流検出用シャント抵抗とアンプ。 */
        attribute mass :> ISQ::mass default 0.002 [kg];
        attribute '消費電力' : PowerValue default 0.2 [W];
        attribute '測定範囲A' : Real default 150.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.008 [m]; :>> width = 0.004 [m]; :>> height = 0.001 [m]; }
    }

    part def 'DCリンクコンデンサ' {
        doc /* インバータの DC リンク用フィルムコンデンサ。 */
        attribute mass :> ISQ::mass default 0.08 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute '静電容量uF' : Real default 2200.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.03 [m]; :>> height = 0.03 [m]; }
    }

    part def 'LPDDRメモリ' {
        doc /* SoC 横の LPDDR5 DRAM パッケージ。 */
        attribute mass :> ISQ::mass default 0.004 [kg];
        attribute '消費電力' : PowerValue default 1.5 [W];
        attribute '容量GiB' : Real default 16.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.015 [m]; :>> width = 0.012 [m]; :>> height = 0.001 [m]; }
    }

    part def 'UFSストレージ' {
        doc /* 地図、学習済みモデル、記録用リングバッファを格納する UFS ストレージ。 */
        attribute mass :> ISQ::mass default 0.003 [kg];
        attribute '消費電力' : PowerValue default 1.0 [W];
        attribute '容量GiB' : Real default 512.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.012 [m]; :>> width = 0.01 [m]; :>> height = 0.001 [m]; }
    }

    part def 'Ethernetスイッチチップ' {
        doc /* TSN 対応 Ethernet スイッチ IC（802.1AS、Qbv、CB）。 */
        attribute mass :> ISQ::mass default 0.006 [kg];
        attribute '消費電力' : PowerValue default 6.0 [W];
        attribute ports : Integer default 12;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.025 [m]; :>> width = 0.025 [m]; :>> height = 0.003 [m]; }
    }

    part def '自動運転SoC' {
        doc /* 自動運転 SoC：CPU クラスタ、GPU、深層学習アクセラレータ。 */
        attribute mass :> ISQ::mass default 0.06 [kg];
        attribute '消費電力' : PowerValue default 250.0 [W];
        attribute tops : Real default 500.0;
        attribute 'CPUコア数' : Integer default 12;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.06 [m]; :>> height = 0.005 [m]; }
        @Safety { asil = Asil::B; }
    }

    part def 'ホストCPU' {
        doc /* ミドルウェアと経路計画を動かす 16 コアの車載アプリケーションプロセッサ。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 55.0 [W];
        attribute 'コア数' : Integer default 16;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.05 [m]; :>> height = 0.004 [m]; }
    }

    part def 'セーフティアイランドコア' {
        doc /* 計算機基板上のロックステップ実時間コア。ハートビート、CAN FD 出力、E2E 保護を担う。 */
        attribute mass :> ISQ::mass default 0.005 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute 'ロックステップ' : Boolean default true;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.03 [m]; :>> height = 0.01 [m]; }
        @Safety { asil = Asil::D; }
    }

    part def 'FPGA型' {
        doc /* センサヘッドの FPGA。点群やレーダキューブの前処理を行う。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 6.0 [W];
        attribute '論理セル数千' : Real default 500.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.035 [m]; :>> width = 0.035 [m]; :>> height = 0.003 [m]; }
    }

    part def '恒温槽付水晶発振器' {
        doc /* 恒温槽付水晶発振器。GNSS 途絶時も時刻を保持する。 */
        attribute mass :> ISQ::mass default 0.03 [kg];
        attribute '消費電力' : PowerValue default 1.5 [W];
        attribute '安定度ppb' : Real default 1.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.025 [m]; :>> width = 0.025 [m]; :>> height = 0.012 [m]; }
    }

    part def '冷却プレート型' {
        doc /* SoC 基板下の液冷コールドプレート。 */
        attribute mass :> ISQ::mass default 1.2 [kg];
        attribute '熱抵抗KW' : Real default 0.02;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.3 [m]; :>> width = 0.25 [m]; :>> height = 0.015 [m]; }
    }

    part def '計算機電源' {
        doc /* 計算機の 24 V から 12 V / 5 V への基板電源。powerDraw は変換損失。 */
        attribute mass :> ISQ::mass default 0.6 [kg];
        attribute '消費電力' : PowerValue default 45.0 [W];
        attribute efficiency : Real default 0.95;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.03 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 部品：センサヘッド部品 */
    /* ------------------------------------------------------------ */

    part def 'センサ取付台' {
        doc /* 防振ゴム付きステンレスブラケット。校正基準面を持つ。 */
        attribute mass :> ISQ::mass default 0.25 [kg];
        attribute '取付角度公差deg' : Real default 0.05;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.06 [m]; :>> height = 0.02 [m]; }
    }

    part def 'センサ窓' {
        doc /* ヒータ付き光学窓またはレドーム。powerDraw はヒータフィルムの電力。 */
        attribute mass :> ISQ::mass default 0.08 [kg];
        attribute '消費電力' : PowerValue default 8.0 [W];
        attribute 'ヒータ電力' : PowerValue default 8 [W];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.1 [m]; :>> height = 0.06 [m]; }
    }

    part def '洗浄ノズル' {
        doc /* センサ窓に向けたウォッシャ液とエアのノズル。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '噴霧角deg' : Real default 40.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.01 [m]; :>> height = 0.01 [m]; }
    }

    part def 'ファイバーレーザ光源' {
        doc /* 1550 nm パルスファイバレーザ光源。 */
        attribute mass :> ISQ::mass default 0.15 [kg];
        attribute '消費電力' : PowerValue default 8.0 [W];
        attribute 'パルス周波数kHz' : Real default 1000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.04 [m]; :>> height = 0.02 [m]; }
    }

    part def 'ポリゴンミラー型' {
        doc /* 水平走査用ポリゴンミラー。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute '回転数rpm' : Real default 6000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.04 [m]; :>> height = 0.03 [m]; }
    }

    part def 'ガルバノミラー型' {
        doc /* 垂直走査用ガルバノミラー。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 2.0 [W];
        attribute '偏向角deg' : Real default 25.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    part def 'APDアレイ型' {
        doc /* InGaAs アバランシェフォトダイオードアレイ。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 1.5 [W];
        attribute '画素数' : Integer default 128;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.01 [m]; }
    }

    part def '時間デジタル変換器' {
        doc /* 時間ディジタル変換器。ビン幅で距離分解能が決まる。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 1.0 [W];
        attribute 'ビン幅' : DurationValue default 0.0 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.015 [m]; :>> width = 0.015 [m]; :>> height = 0.002 [m]; }
    }

    part def 'VCSELアレイ' {
        doc /* 905 nm VCSEL アレイ（フラッシュ式 LiDAR の発光部）。 */
        attribute mass :> ISQ::mass default 0.03 [kg];
        attribute '消費電力' : PowerValue default 4.0 [W];
        attribute '発光素子数' : Integer default 256;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.005 [m]; }
    }

    part def 'SPADアレイ' {
        doc /* SPAD 受光アレイ（フラッシュ式 LiDAR の受光部）。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 2.0 [W];
        attribute '画素数' : Integer default 30000;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.005 [m]; }
    }

    part def 'レーダMMIC' {
        doc /* 77 GHz レーダ送受信 MMIC（送信 3、受信 4 チャネル）。1 台に 4 個カスケード。 */
        attribute mass :> ISQ::mass default 0.003 [kg];
        attribute '消費電力' : PowerValue default 1.5 [W];
        attribute '送信チャネル数' : Integer default 3;
        attribute '受信チャネル数' : Integer default 4;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.01 [m]; :>> height = 0.001 [m]; }
    }

    part def 'レーダアンテナ基板' {
        doc /* 4D イメージングレーダの導波管アンテナ基板。 */
        attribute mass :> ISQ::mass default 0.08 [kg];
        attribute '仮想チャネル数' : Integer default 192;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.004 [m]; :>> width = 0.14 [m]; :>> height = 0.1 [m]; }
    }

    part def 'レーダ処理部型' {
        doc /* レーダ信号処理器：距離ドップラ FFT、CFAR、到来角推定。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute 'キューブ更新Hz' : Real default 20.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.002 [m]; }
    }

    part def 'イメージセンサ' {
        doc /* HDR と LED フリッカ抑制付き車載 CMOS イメージセンサ。hdrDb はダイナミックレンジ（トンネル出口、逆光対策）。 */
        attribute mass :> ISQ::mass default 0.005 [kg];
        attribute '消費電力' : PowerValue default 0.6 [W];
        attribute '画素数MP' : Real default 8.0;
        attribute 'HDR_dB' : Real default 140.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.012 [m]; :>> width = 0.012 [m]; :>> height = 0.003 [m]; }
    }

    part def 'カメラレンズ' {
        doc /* ガラスレンズ。焦点距離で画角が決まる。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '焦点距離' : LengthValue default 0.012 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.025 [m]; :>> height = 0.025 [m]; }
    }

    part def '映像シリアライザ' {
        doc /* 映像シリアライザ（GMSL / ASA）。 */
        attribute mass :> ISQ::mass default 0.003 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute 'リンクGbps' : Real default 6.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.01 [m]; :>> height = 0.002 [m]; }
    }

    part def 'マイクロボロメータ' {
        doc /* 640 x 512 非冷却マイクロボロメータ（遠赤外 8 から 14 um）。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 0.4 [W];
        attribute 'NETD_mK' : Real default 50.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.015 [m]; :>> width = 0.015 [m]; :>> height = 0.005 [m]; }
    }

    part def '赤外線シャッタ' {
        doc /* フラットフィールド補正用シャッタ。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 0.2 [W];
        attribute '補正周期' : DurationValue default 120 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.005 [m]; }
    }

    part def 'GNSS受信機' {
        doc /* 多周波、マルチ GNSS の RTK 受信機。PPS 出力付き。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 1.5 [W];
        attribute 'PPSジッタ' : DurationValue default 0.0 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.025 [m]; :>> height = 0.004 [m]; }
    }

    part def 'CLAS受信機型' {
        doc /* 準天頂衛星みちびきの L6 信号（CLAS センチメータ級補強）受信部。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 0.8 [W];
        attribute '収束時間' : DurationValue default 60 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.025 [m]; :>> width = 0.02 [m]; :>> height = 0.004 [m]; }
    }

    part def 'GNSSアンテナ' {
        doc /* キャブ屋根上の多周波 GNSS アンテナ。 */
        attribute mass :> ISQ::mass default 0.15 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '利得dBi' : Real default 4.0;
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.06 [m]; :>> height = 0.03 [m]; }
    }

    part def 'IMUセンサ' {
        doc /* 6 軸 MEMS IMU（車載グレード）。ジャイロバイアス安定性は deg/h。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute 'ジャイロバイアスdegh' : Real default 1.0;
        attribute '更新周波数Hz' : Real default 200.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.06 [m]; :>> height = 0.03 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 部品：空気ブレーキ部品 */
    /* ------------------------------------------------------------ */

    part def '電磁弁' {
        doc /* 電空モジュレータの 2/2 ソレノイド弁。 */
        attribute mass :> ISQ::mass default 0.35 [kg];
        attribute '消費電力' : PowerValue default 8.0 [W];
        attribute '切替時間' : DurationValue default 0.008 [s];
        attribute 'コイル抵抗Ohm' : Real default 12.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.04 [m]; :>> height = 0.04 [m]; }
    }

    part def 'リレーピストン' {
        doc /* パイロット圧を増幅して出力ポートへ送るリレーピストン。 */
        attribute mass :> ISQ::mass default 0.6 [kg];
        attribute '応答時間' : DurationValue default 0.012 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.06 [m]; :>> height = 0.05 [m]; }
    }

    part def 'ブレーキ圧センサ' {
        doc /* 出力圧センサ。回路ごとに 2 個で妥当性を照合する。 */
        attribute mass :> ISQ::mass default 0.08 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '測定範囲kPa' : Real default 1000.0;
        attribute '精度kPa' : Real default 10.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    part def 'ブレーキキャリパ' {
        doc /* 22.5 インチ用エアディスクブレーキのキャリパ。 */
        attribute mass :> ISQ::mass default 18.0 [kg];
        attribute '締付力' : ForceValue default 200000 [N];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.12 [m]; :>> height = 0.3 [m]; }
    }

    part def 'ブレーキパッド' {
        doc /* ディスクブレーキパッド（1 組）。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute thickness : LengthValue default 0.03 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.1 [m]; :>> height = 0.2 [m]; }
    }

    part def 'ブレーキロータ' {
        doc /* ベンチレーテッドディスクロータ（直径 430 mm）。 */
        attribute mass :> ISQ::mass default 32.0 [kg];
        attribute diameter : LengthValue default 0.43 [m];
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.215 [m]; :>> height = 0.045 [m]; }
    }

    part def 'パッド摩耗センサ' {
        doc /* パッド摩耗センサ。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '閾値mm' : Real default 3.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.01 [m]; :>> height = 0.01 [m]; }
    }

    part def 'ブレーキドラム' {
        doc /* ドラムブレーキのドラム（410 mm 径）。 */
        attribute mass :> ISQ::mass default 45.0 [kg];
        attribute diameter : LengthValue default 0.41 [m];
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.21 [m]; :>> height = 0.22 [m]; }
    }

    part def 'ブレーキシュー型' {
        doc /* ドラムブレーキのシューとライニング（1 組）。 */
        attribute mass :> ISQ::mass default 9.0 [kg];
        attribute 'ライニング幅' : LengthValue default 0.2 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.4 [m]; :>> width = 0.2 [m]; :>> height = 0.05 [m]; }
    }

    part def 'Sカムシャフト' {
        doc /* S カムシャフト。チャンバのストロークをシューの拡張に変える。 */
        attribute mass :> ISQ::mass default 4.5 [kg];
        attribute 'カム角deg' : Real default 30.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.3 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def 'スラックアジャスタ型' {
        doc /* 自動すきま調整装置。 */
        attribute mass :> ISQ::mass default 2.5 [kg];
        attribute 'アーム長' : LengthValue default 0.15 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.06 [m]; :>> height = 0.04 [m]; }
    }

    part def 'ブレーキチャンバ型' {
        doc /* サービスブレーキチャンバ（タイプ 24）。 */
        attribute mass :> ISQ::mass default 3.5 [kg];
        attribute '有効面積m2' : Real default 0.0155;
        port '空気入口' : ~'空気ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.2 [m]; :>> width = 0.18 [m]; :>> height = 0.18 [m]; }
    }

    part def 'スプリングブレーキチャンバ' {
        doc /* スプリングブレーキチャンバ（サービス側と駐車用ばね）。ホイールパーク方式。 */
        attribute mass :> ISQ::mass default 6.0 [kg];
        attribute 'ばね力' : ForceValue default 9000 [N];
        port '空気入口' : ~'空気ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.35 [m]; :>> width = 0.2 [m]; :>> height = 0.2 [m]; }
    }

    part def '車輪速センサ型' {
        doc /* 100 歯トーンリング用の誘導式車輪速センサ。 */
        attribute mass :> ISQ::mass default 0.15 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '歯数' : Integer default 100;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    part def 'ハブベアリング' {
        doc /* ユニットハブベアリング。 */
        attribute mass :> ISQ::mass default 12.0 [kg];
        attribute '定格荷重' : ForceValue default 60000 [N];
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.12 [m]; :>> height = 0.15 [m]; }
    }

    part def 'エアコンプレッサ' {
        doc /* エンジン駆動の 2 気筒エアコンプレッサ。 */
        attribute mass :> ISQ::mass default 22.0 [kg];
        attribute '排気量cc' : Real default 636.0;
        attribute 'カットアウト圧力' : PressureValue default 980000 [Pa];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.3 [m]; :>> width = 0.25 [m]; :>> height = 0.25 [m]; }
    }

    part def 'ドライヤカートリッジ' {
        doc /* 乾燥剤カートリッジ（オイルセパレータ付き）。 */
        attribute mass :> ISQ::mass default 2.5 [kg];
        attribute '整備間隔km' : Real default 300000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.15 [m]; :>> height = 0.2 [m]; }
    }

    part def 'ドライヤヒータ' {
        doc /* 寒冷地用パージ弁ヒータ。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 100.0 [W];
        attribute '作動温度C以下' : Real default 5.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.03 [m]; :>> height = 0.02 [m]; }
    }

    part def 'ガバナ型' {
        doc /* 電子式コンプレッサガバナとアンローダ弁。 */
        attribute mass :> ISQ::mass default 0.4 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute 'カットイン圧力' : PressureValue default 830000 [Pa];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def '保護弁型' {
        doc /* 4 回路保護弁。1 回路が漏れても他の回路の圧力を保つ。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '回路数' : Integer default 4;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.1 [m]; :>> height = 0.08 [m]; }
    }

    part def 'ドレンバルブ' {
        doc /* エアタンクの自動ドレン弁。 */
        attribute mass :> ISQ::mass default 0.3 [kg];
        attribute 'ヒータ付き' : Boolean default false;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.04 [m]; :>> height = 0.04 [m]; }
    }

    part def 'リターダロータ' {
        doc /* 永久磁石式リターダのロータ（プロペラシャフトに直結）。 */
        attribute mass :> ISQ::mass default 28.0 [kg];
        attribute diameter : LengthValue default 0.42 [m];
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.21 [m]; :>> height = 0.08 [m]; }
    }

    part def 'リターダ磁石列' {
        doc /* リターダの永久磁石とヨーク。 */
        attribute mass :> ISQ::mass default 35.0 [kg];
        attribute '磁極数' : Integer default 16;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.2 [m]; :>> width = 0.45 [m]; :>> height = 0.45 [m]; }
    }

    part def 'リターダ切替アクチュエータ' {
        doc /* 磁石の位相を切り替える空圧アクチュエータ（4 段）。 */
        attribute mass :> ISQ::mass default 3.0 [kg];
        attribute '消費電力' : PowerValue default 6.0 [W];
        attribute steps : Integer default 4;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def '排気ブレーキバルブ' {
        doc /* 排気ブレーキのバタフライ弁と空圧アクチュエータ。 */
        attribute mass :> ISQ::mass default 4.5 [kg];
        attribute '消費電力' : PowerValue default 4.0 [W];
        attribute '閉時間' : DurationValue default 0.15 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.15 [m]; :>> height = 0.12 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 部品：操舵とパワートレインの部品 */
    /* ------------------------------------------------------------ */

    part def 'モータロータ' {
        doc /* EPS モータの永久磁石ロータ。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '極対数' : Integer default 5;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.06 [m]; :>> height = 0.06 [m]; }
    }

    part def 'レゾルバ' {
        doc /* ロータ位置センサ（巻線ごとに 1 個）。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 0.2 [W];
        attribute '精度deg' : Real default 0.5;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.04 [m]; :>> height = 0.01 [m]; }
    }

    part def 'ホール素子' {
        doc /* トルク角センサのホール素子。 */
        attribute mass :> ISQ::mass default 0.005 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '分解能bit' : Integer default 14;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.005 [m]; :>> width = 0.005 [m]; :>> height = 0.002 [m]; }
    }

    part def 'ボールナット型' {
        doc /* 入力ウォームのボールナット。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute 'リードmm' : Real default 12.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def 'セクタシャフト型' {
        doc /* セクタシャフトとピットマンアーム側スプライン。 */
        attribute mass :> ISQ::mass default 6.0 [kg];
        attribute 'スプライン歯数' : Integer default 36;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def 'ピットマンアーム型' {
        doc /* 鍛造ピットマンアーム。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute 'アーム長' : LengthValue default 0.28 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.3 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def 'ドラッグリンク型' {
        doc /* ピットマンアームからナックルへのドラッグリンク。 */
        attribute mass :> ISQ::mass default 6.0 [kg];
        attribute 'リンク長' : LengthValue default 0.9 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.9 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def 'タイロッド型' {
        doc /* ボールジョイント付きタイロッド。 */
        attribute mass :> ISQ::mass default 8.0 [kg];
        attribute 'ロッド長' : LengthValue default 1.8 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 1.8 [m]; :>> height = 0.05 [m]; }
    }

    part def 'ステアリングホイール型' {
        doc /* ステアリングホイール（直径 450 mm、エアバッグ付き）。 */
        attribute mass :> ISQ::mass default 3.5 [kg];
        attribute diameter : LengthValue default 0.45 [m];
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.225 [m]; :>> height = 0.08 [m]; }
    }

    part def 'コラムスイッチ型' {
        doc /* コラムスイッチ（ウインカ、ワイパ、排気ブレーキ）。 */
        attribute mass :> ISQ::mass default 0.4 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute functions : Integer default 12;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.3 [m]; :>> height = 0.08 [m]; }
    }

    part def 'クロックスプリング型' {
        doc /* ステアリングのクロックスプリング（スパイラルケーブル）。 */
        attribute mass :> ISQ::mass default 0.2 [kg];
        attribute '巻数' : Real default 5.5;
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.07 [m]; :>> height = 0.03 [m]; }
    }

    part def '舵角センサ型' {
        doc /* 冗長のステアリング角センサ。 */
        attribute mass :> ISQ::mass default 0.08 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '分解能deg' : Real default 0.1;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.06 [m]; :>> height = 0.02 [m]; }
    }

    part def 'サプライポンプ' {
        doc /* カム駆動のコモンレール高圧ポンプ。 */
        attribute mass :> ISQ::mass default 9.0 [kg];
        attribute '最大圧力' : PressureValue default 220000000 [Pa];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.2 [m]; :>> width = 0.15 [m]; :>> height = 0.15 [m]; }
    }

    part def '燃料レール' {
        doc /* 鍛造コモンレール（圧力センサ、プレッシャリミッタ付き）。 */
        attribute mass :> ISQ::mass default 2.5 [kg];
        attribute '容積cc' : Real default 30.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.6 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def 'インジェクタ' {
        doc /* ソレノイドインジェクタ（1 サイクル最大 5 回噴射）。 */
        attribute mass :> ISQ::mass default 0.5 [kg];
        attribute '消費電力' : PowerValue default 12.0 [W];
        attribute '噴孔数' : Integer default 8;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.03 [m]; :>> height = 0.2 [m]; }
    }

    part def '可変ノズルアクチュエータ' {
        doc /* 可変ノズルターボの電動ベーンアクチュエータ。 */
        attribute mass :> ISQ::mass default 1.2 [kg];
        attribute '消費電力' : PowerValue default 6.0 [W];
        attribute 'ストローク時間' : DurationValue default 0.15 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.08 [m]; :>> height = 0.06 [m]; }
    }

    part def '速度センサ' {
        doc /* ホール式回転センサ（クランク、カム、ターボ、変速機出力）。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '最高回転数rpm' : Real default 150000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    part def 'EGRバルブ' {
        doc /* EGR バルブ（電動）。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '消費電力' : PowerValue default 15.0 [W];
        attribute 'ストローク時間' : DurationValue default 0.1 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.1 [m]; :>> height = 0.1 [m]; }
    }

    part def 'EGRクーラ' {
        doc /* EGR クーラ（水冷）。 */
        attribute mass :> ISQ::mass default 9.0 [kg];
        attribute effectiveness : Real default 0.85;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.5 [m]; :>> width = 0.15 [m]; :>> height = 0.15 [m]; }
    }

    part def 'スタータモータ' {
        doc /* 24 V スタータモータ（6 kW）。 */
        attribute mass :> ISQ::mass default 14.0 [kg];
        attribute '定格出力' : PowerValue default 6 [kW];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.35 [m]; :>> width = 0.15 [m]; :>> height = 0.15 [m]; }
    }

    part def '酸化触媒型' {
        doc /* ディーゼル酸化触媒（DOC）。 */
        attribute mass :> ISQ::mass default 22.0 [kg];
        attribute 'セル密度' : Real default 400.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.3 [m]; :>> height = 0.3 [m]; }
    }

    part def 'DPF型' {
        doc /* ウォールフロー型ディーゼル微粒子捕集フィルタ（DPF）。 */
        attribute mass :> ISQ::mass default 40.0 [kg];
        attribute 'ろ過効率' : Real default 0.99;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.33 [m]; :>> width = 0.3 [m]; :>> height = 0.3 [m]; }
    }

    part def 'SCR触媒型' {
        doc /* 尿素 SCR 触媒とアンモニアスリップ触媒。 */
        attribute mass :> ISQ::mass default 48.0 [kg];
        attribute 'NOx浄化率' : Real default 0.97;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.38 [m]; :>> width = 0.3 [m]; :>> height = 0.3 [m]; }
    }

    part def '尿素水噴射装置型' {
        doc /* 尿素水（AdBlue）噴射弁。 */
        attribute mass :> ISQ::mass default 1.5 [kg];
        attribute '消費電力' : PowerValue default 15.0 [W];
        attribute '最大噴射量gs' : Real default 1.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def 'NOxセンサ' {
        doc /* SCR 上流または下流の NOx センサ。 */
        attribute mass :> ISQ::mass default 0.2 [kg];
        attribute '消費電力' : PowerValue default 4.0 [W];
        attribute '精度ppm' : Real default 10.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.03 [m]; :>> height = 0.03 [m]; }
    }

    part def '差圧センサ' {
        doc /* DPF 前後差圧センサ（再生判定）。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 0.2 [W];
        attribute '測定範囲kPa' : Real default 50.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.03 [m]; :>> height = 0.02 [m]; }
    }

    part def '尿素水タンク' {
        doc /* 尿素水タンク 40 L（ヒータ、液面センサ付き）。 */
        attribute mass :> ISQ::mass default 18.0 [kg];
        attribute '消費電力' : PowerValue default 50.0 [W];
        attribute volume : VolumeValue default 0.04 [m^3];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.45 [m]; :>> width = 0.35 [m]; :>> height = 0.35 [m]; }
    }

    part def '尿素水ポンプ' {
        doc /* 尿素水供給ポンプ。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '消費電力' : PowerValue default 30.0 [W];
        attribute pressure : PressureValue default 900000 [Pa];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.1 [m]; :>> height = 0.1 [m]; }
    }

    part def 'クラッチアクチュエータ' {
        doc /* 空圧クラッチアクチュエータ（ストロークセンサ付き）。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute '消費電力' : PowerValue default 5.0 [W];
        attribute stroke : LengthValue default 0.035 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def 'シフトアクチュエータ型' {
        doc /* XY シフトシリンダと電磁弁ブロック。 */
        attribute mass :> ISQ::mass default 8.0 [kg];
        attribute '消費電力' : PowerValue default 10.0 [W];
        attribute '変速時間' : DurationValue default 0.4 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.15 [m]; :>> height = 0.12 [m]; }
    }

    part def '主変速機型' {
        doc /* メインギヤボックス（6 段、ツインカウンタシャフト）。 */
        attribute mass :> ISQ::mass default 190.0 [kg];
        attribute '変速比' : Integer default 6;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.6 [m]; :>> width = 0.45 [m]; :>> height = 0.45 [m]; }
    }

    part def 'レンジ切替機構型' {
        doc /* プラネタリ式レンジ切替（ハイ / ロー）。 */
        attribute mass :> ISQ::mass default 60.0 [kg];
        attribute '低速段比' : Real default 3.7;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.4 [m]; :>> height = 0.4 [m]; }
    }

    part def 'プロペラシャフト型' {
        doc /* プロペラシャフト（1 本分、中間軸受の前後に 1 本ずつ）。 */
        attribute mass :> ISQ::mass default 38.0 [kg];
        attribute 'シャフト長' : LengthValue default 1.675 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 1.675 [m]; :>> width = 0.12 [m]; :>> height = 0.12 [m]; }
    }

    part def '自在継手' {
        doc /* 十字軸自在継手。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute '最大角度deg' : Real default 15.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.15 [m]; :>> height = 0.15 [m]; }
    }

    part def 'センターベアリング型' {
        doc /* プロペラシャフト中間軸受。 */
        attribute mass :> ISQ::mass default 3.0 [kg];
        attribute '定格荷重' : ForceValue default 12000 [N];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.2 [m]; :>> height = 0.15 [m]; }
    }

    part def '終減速機型' {
        doc /* ハイポイドファイナルドライブ（デフ）。 */
        attribute mass :> ISQ::mass default 160.0 [kg];
        attribute '減速比' : Real default 3.9;
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.25 [m]; :>> height = 0.45 [m]; }
    }

    part def '軸間差動装置型' {
        doc /* 前後軸間デフ（2 デフのタンデム用）。 */
        attribute mass :> ISQ::mass default 35.0 [kg];
        attribute 'ロック可能' : Boolean default true;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.25 [m]; :>> height = 0.25 [m]; }
    }

    part def 'デフロックアクチュエータ' {
        doc /* デフロック空圧アクチュエータ。 */
        attribute mass :> ISQ::mass default 1.5 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute '係合時間' : DurationValue default 0.3 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.06 [m]; :>> height = 0.06 [m]; }
    }

    part def 'アクスルシャフト' {
        doc /* アクスルシャフト（片側）。 */
        attribute mass :> ISQ::mass default 25.0 [kg];
        attribute 'スプライン歯数' : Integer default 38;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.25 [m]; :>> height = 0.05 [m]; }
    }

    part def 'フィードポンプ型' {
        doc /* 燃料フィードポンプ（電動）。 */
        attribute mass :> ISQ::mass default 1.2 [kg];
        attribute '消費電力' : PowerValue default 60.0 [W];
        attribute '流量Lh' : Real default 250.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def '燃料フィルタ型' {
        doc /* 燃料フィルタと水分離器。 */
        attribute mass :> ISQ::mass default 1.8 [kg];
        attribute 'ろ過粒度um' : Real default 4.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.1 [m]; :>> height = 0.25 [m]; }
    }

    part def '燃料残量センサ' {
        doc /* フロート式燃料残量センサ。 */
        attribute mass :> ISQ::mass default 0.3 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '精度比率' : Real default 0.02;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.05 [m]; :>> height = 0.55 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 部品：シャシーと荷箱の部品 */
    /* ------------------------------------------------------------ */

    part def 'リーフスプリング' {
        doc /* 前軸用テーパリーフスプリング（片側）。 */
        attribute mass :> ISQ::mass default 55.0 [kg];
        attribute 'ばね定数Nmm' : Real default 300.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 1.5 [m]; :>> width = 0.09 [m]; :>> height = 0.12 [m]; }
    }

    part def 'ショックアブソーバ' {
        doc /* 油圧ショックアブソーバ。 */
        attribute mass :> ISQ::mass default 6.0 [kg];
        attribute stroke : LengthValue default 0.2 [m];
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.04 [m]; :>> height = 0.45 [m]; }
    }

    part def 'スタビライザ型' {
        doc /* スタビライザ。 */
        attribute mass :> ISQ::mass default 22.0 [kg];
        attribute diameter : LengthValue default 0.05 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.9 [m]; :>> height = 0.08 [m]; }
    }

    part def 'エアばね型' {
        doc /* 後軸用ローリングローブ式エアばね。 */
        attribute mass :> ISQ::mass default 9.0 [kg];
        attribute '定格荷重' : ForceValue default 30000 [N];
        port '空気入口' : ~'空気ポート';
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.15 [m]; :>> height = 0.3 [m]; }
    }

    part def '車高センサ型' {
        doc /* 車高センサ（ECAS 用）。 */
        attribute mass :> ISQ::mass default 0.2 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute range : LengthValue default 0.2 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.04 [m]; :>> height = 0.04 [m]; }
    }

    part def '車高調整バルブブロック' {
        doc /* ECAS の電磁弁ブロック（左右独立に給排気）。 */
        attribute mass :> ISQ::mass default 3.0 [kg];
        attribute '消費電力' : PowerValue default 16.0 [W];
        attribute 'チャネル数' : Integer default 2;
        port '空気入口' : ~'空気ポート';
        port '空気出口' : '空気ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.12 [m]; :>> height = 0.1 [m]; }
    }

    part def 'トルクロッド' {
        doc /* トルクロッド（前後位置決め）。 */
        attribute mass :> ISQ::mass default 12.0 [kg];
        attribute 'ロッド長' : LengthValue default 0.7 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.7 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def 'ウイングパネル' {
        doc /* ウイングパネル（アルミハニカム、片側）。ガルウイング状に開く。 */
        attribute mass :> ISQ::mass default 220.0 [kg];
        attribute 'パネル長' : LengthValue default 9.0 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 9.0 [m]; :>> width = 0.05 [m]; :>> height = 2.4 [m]; }
    }

    part def 'ウイングシリンダ' {
        doc /* ウイング開閉用の油圧シリンダ。 */
        attribute mass :> ISQ::mass default 14.0 [kg];
        attribute stroke : LengthValue default 0.9 [m];
        port '作動油入口' : ~'油圧ポート';
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.05 [m]; :>> height = 1.2 [m]; }
    }

    part def '油圧ポンプ' {
        doc /* ウイング用ギヤポンプ。 */
        attribute mass :> ISQ::mass default 6.0 [kg];
        attribute '排気量cc' : Real default 4.0;
        port '作動油出口' : '油圧ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.1 [m]; :>> height = 0.1 [m]; }
    }

    part def '作動油タンク' {
        doc /* 作動油タンク 8 L。 */
        attribute mass :> ISQ::mass default 5.0 [kg];
        attribute volume : VolumeValue default 0.008 [m^3];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.15 [m]; :>> height = 0.2 [m]; }
    }

    part def 'ポンプモータ' {
        doc /* ブラシレスポンプモータ（冷却水または作動油用）。 */
        attribute mass :> ISQ::mass default 1.5 [kg];
        attribute '消費電力' : PowerValue default 120.0 [W];
        attribute '回転数rpm' : Real default 4000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def '後扉型' {
        doc /* 観音開きのリヤドア（片側）。 */
        attribute mass :> ISQ::mass default 60.0 [kg];
        attribute '扉幅' : LengthValue default 1.15 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 1.15 [m]; :>> height = 2.4 [m]; }
    }

    part def '扉センサ' {
        doc /* ドア開閉と施錠の検知スイッチ。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute 'IP等級' : Integer default 67;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.03 [m]; :>> height = 0.02 [m]; }
    }

    part def '荷室灯' {
        doc /* 荷室 LED 照明。 */
        attribute mass :> ISQ::mass default 0.4 [kg];
        attribute '消費電力' : PowerValue default 6.0 [W];
        attribute '光束lm' : Real default 800.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.4 [m]; :>> width = 0.05 [m]; :>> height = 0.03 [m]; }
    }

    part def 'ラッシングレール' {
        doc /* 荷締め用ラッシングレール（片側）。 */
        attribute mass :> ISQ::mass default 18.0 [kg];
        attribute pitch : LengthValue default 0.25 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 8.7 [m]; :>> width = 0.04 [m]; :>> height = 0.08 [m]; }
    }

    part def '床荷重センサ' {
        doc /* 床下ロードセル（積載重量の推定）。 */
        attribute mass :> ISQ::mass default 0.8 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute capacity : ForceValue default 60000 [N];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.1 [m]; :>> height = 0.05 [m]; }
    }

    part def '荷室カメラ' {
        doc /* 荷室監視カメラ（荷崩れ検知）。 */
        attribute mass :> ISQ::mass default 0.2 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute '画素数MP' : Real default 2.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def '荷室温度センサ' {
        doc /* 荷室温度センサ。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '精度C' : Real default 0.5;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 部品：キャブ部品 */
    /* ------------------------------------------------------------ */

    part def 'シートフレーム型' {
        doc /* シートフレームとクッション。 */
        attribute mass :> ISQ::mass default 18.0 [kg];
        attribute 'スライド量' : LengthValue default 0.2 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.5 [m]; :>> width = 0.45 [m]; :>> height = 0.8 [m]; }
    }

    part def 'シートエアばね' {
        doc /* シートのエアサスペンション。 */
        attribute mass :> ISQ::mass default 2.5 [kg];
        attribute 'ストローク量' : LengthValue default 0.1 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.25 [m]; :>> height = 0.15 [m]; }
    }

    part def 'シートヒータ' {
        doc /* シートヒータ。 */
        attribute mass :> ISQ::mass default 0.3 [kg];
        attribute '消費電力' : PowerValue default 60.0 [W];
        attribute '最高温度C' : Real default 40.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.4 [m]; :>> width = 0.4 [m]; :>> height = 0.01 [m]; }
    }

    part def 'シートベルトプリテンショナ' {
        doc /* シートベルトプリテンショナ。 */
        attribute mass :> ISQ::mass default 0.8 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '引張力' : ForceValue default 2500 [N];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def '着座センサ型' {
        doc /* 着座センサ（無人運行時の乗員検知）。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute '閾値kg' : Real default 20.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.3 [m]; :>> width = 0.3 [m]; :>> height = 0.005 [m]; }
    }

    part def '仮眠ベッド型' {
        doc /* 仮眠用ベッド（フルキャブ後部）。 */
        attribute mass :> ISQ::mass default 25.0 [kg];
        attribute 'ベッド幅' : LengthValue default 0.6 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.6 [m]; :>> width = 2.0 [m]; :>> height = 0.15 [m]; }
    }

    part def 'チルトポンプ' {
        doc /* キャブチルト用の電動油圧ポンプ。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute '消費電力' : PowerValue default 400.0 [W];
        attribute '最大圧力' : PressureValue default 20000000 [Pa];
        port '作動油出口' : '油圧ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.2 [m]; :>> width = 0.12 [m]; :>> height = 0.12 [m]; }
    }

    part def 'チルトシリンダ' {
        doc /* キャブチルトシリンダ。 */
        attribute mass :> ISQ::mass default 5.0 [kg];
        attribute stroke : LengthValue default 0.3 [m];
        port '作動油入口' : ~'油圧ポート';
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.04 [m]; :>> height = 0.45 [m]; }
    }

    part def 'キャブロック' {
        doc /* キャブロック（前倒れ防止の機械式ラッチ）。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '保持力' : ForceValue default 40000 [N];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.08 [m]; }
    }

    part def 'ロックセンサ' {
        doc /* キャブロックの施錠検知センサ。無人発進の条件に使う。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute 'IP等級' : Integer default 69;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    part def 'アクセルペダルセンサ' {
        doc /* 二重系のアクセルペダルセンサ。 */
        attribute mass :> ISQ::mass default 0.6 [kg];
        attribute '消費電力' : PowerValue default 0.1 [W];
        attribute 'トラック数' : Integer default 2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.1 [m]; :>> height = 0.1 [m]; }
    }

    part def 'フットブレーキバルブ' {
        doc /* 2 回路式フットブレーキバルブ。 */
        attribute mass :> ISQ::mass default 3.0 [kg];
        attribute '回路数' : Integer default 2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.12 [m]; :>> height = 0.2 [m]; }
    }

    part def 'シフトセレクタ' {
        doc /* AMT のシフトセレクタ（D、N、R、M）。 */
        attribute mass :> ISQ::mass default 0.5 [kg];
        attribute '消費電力' : PowerValue default 0.3 [W];
        attribute 'ポジション数' : Integer default 4;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.12 [m]; }
    }

    part def '駐車ブレーキスイッチ型' {
        doc /* 電子パーキングブレーキスイッチ。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '接点数' : Integer default 2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.03 [m]; :>> height = 0.03 [m]; }
    }

    part def 'リターダレバー型' {
        doc /* リターダと排気ブレーキの段数レバー。 */
        attribute mass :> ISQ::mass default 0.2 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute 'ポジション数' : Integer default 5;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.03 [m]; :>> height = 0.03 [m]; }
    }

    part def 'メータディスプレイ' {
        doc /* 12.3 インチメータ表示器。 */
        attribute mass :> ISQ::mass default 1.2 [kg];
        attribute '消費電力' : PowerValue default 12.0 [W];
        attribute '輝度nit' : Real default 1000.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.3 [m]; :>> height = 0.12 [m]; }
    }

    part def 'センターディスプレイ型' {
        doc /* 10.1 インチセンタディスプレイ（点検、遠隔監視の指示表示）。 */
        attribute mass :> ISQ::mass default 1.0 [kg];
        attribute '消費電力' : PowerValue default 10.0 [W];
        attribute '輝度nit' : Real default 800.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.25 [m]; :>> height = 0.16 [m]; }
    }

    part def '自動運行表示灯' {
        doc /* 自動運転作動表示灯（外部向け、ターコイズ）。 */
        attribute mass :> ISQ::mass default 0.15 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute '可視距離m' : Real default 100.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.03 [m]; :>> height = 0.03 [m]; }
    }

    part def 'ブザー型' {
        doc /* 警報ブザー。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 1.0 [W];
        attribute '音圧dB' : Real default 85.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.03 [m]; :>> height = 0.02 [m]; }
    }

    part def '引継ぎボタン型' {
        doc /* 引継ぎスイッチ（構内での手動運転への切替）。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '接点数' : Integer default 2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.03 [m]; :>> height = 0.02 [m]; }
    }

    part def '非常停止スイッチ型' {
        doc /* 非常停止スイッチ（キャブ内と車外の 2 か所）。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '接点数' : Integer default 2;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def 'ドライバモニタカメラ' {
        doc /* 車内監視カメラ（乗員の有無と状態）。 */
        attribute mass :> ISQ::mass default 0.15 [kg];
        attribute '消費電力' : PowerValue default 2.0 [W];
        attribute 'フレームレートHz' : Real default 30.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.04 [m]; :>> height = 0.04 [m]; }
    }

    part def 'エアコンコンプレッサ' {
        doc /* ベルト駆動冷媒コンプレッサ（R1234yf）。 */
        attribute mass :> ISQ::mass default 9.0 [kg];
        attribute '排気量cc' : Real default 160.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.2 [m]; :>> width = 0.15 [m]; :>> height = 0.15 [m]; }
    }

    part def 'エバポレータ型' {
        doc /* キャブ用エバポレータ。 */
        attribute mass :> ISQ::mass default 3.0 [kg];
        attribute capacity : PowerValue default 5 [kW];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.3 [m]; :>> height = 0.25 [m]; }
    }

    part def 'コンデンサ型' {
        doc /* 冷媒コンデンサ。 */
        attribute mass :> ISQ::mass default 4.0 [kg];
        attribute capacity : PowerValue default 7 [kW];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.04 [m]; :>> width = 0.7 [m]; :>> height = 0.4 [m]; }
    }

    part def 'ブロワ型' {
        doc /* キャブブロワファン。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '消費電力' : PowerValue default 150.0 [W];
        attribute '風量m3h' : Real default 500.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.15 [m]; :>> height = 0.15 [m]; }
    }

    part def 'ウォッシャポンプ' {
        doc /* センサ洗浄用ウォッシャポンプ。 */
        attribute mass :> ISQ::mass default 0.5 [kg];
        attribute '消費電力' : PowerValue default 40.0 [W];
        attribute pressure : PressureValue default 300000 [Pa];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.06 [m]; :>> height = 0.06 [m]; }
    }

    part def 'ウォッシャタンク' {
        doc /* センサ洗浄液タンク 12 L。 */
        attribute mass :> ISQ::mass default 1.2 [kg];
        attribute '容積L' : Real default 12.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.15 [m]; :>> height = 0.3 [m]; }
    }

    part def 'エアナイフ' {
        doc /* LiDAR 窓の水滴を飛ばすエアナイフ。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '流量Ls' : Real default 2.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 部品：電源、熱、通信の部品 */
    /* ------------------------------------------------------------ */

    part def '鉛蓄電池' {
        doc /* 12 V 鉛バッテリ（大型車用 150 Ah）。2 個直列で 24 V。 */
        attribute mass :> ISQ::mass default 42.0 [kg];
        attribute '容量Ah' : Real default 150.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.5 [m]; :>> width = 0.22 [m]; :>> height = 0.25 [m]; }
    }

    part def 'LFPセル' {
        doc /* 3.2 V 100 Ah 角形 LFP セル。 */
        attribute mass :> ISQ::mass default 2.0 [kg];
        attribute '容量Ah' : Real default 100.0;
        attribute '公称電圧' : ElectricPotentialValue default 3.2 [V];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.17 [m]; :>> height = 0.2 [m]; }
    }

    part def 'セルモニタ型' {
        doc /* セル電圧と温度の監視 IC。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 0.2 [W];
        attribute 'セル群' : Integer default 8;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.003 [m]; }
    }

    part def 'コンタクタ型' {
        doc /* バッテリ断路コンタクタ。 */
        attribute mass :> ISQ::mass default 0.4 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute '定格電流' : ElectricCurrentValue default 200 [A];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def '電圧レギュレータ' {
        doc /* オルタネータのレギュレータ（LIN で設定電圧を指令）。 */
        attribute mass :> ISQ::mass default 0.3 [kg];
        attribute '消費電力' : PowerValue default 1.0 [W];
        attribute '設定値' : ElectricPotentialValue default 28 [V];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.04 [m]; :>> height = 0.02 [m]; }
    }

    part def '整流ブリッジ' {
        doc /* オルタネータの整流ダイオードブリッジ。 */
        attribute mass :> ISQ::mass default 0.5 [kg];
        attribute 'ダイオード数' : Integer default 6;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.08 [m]; :>> height = 0.02 [m]; }
    }

    part def 'オルタネータステータ' {
        doc /* オルタネータのステータとロータ。 */
        attribute mass :> ISQ::mass default 11.0 [kg];
        attribute '極対数' : Integer default 6;
        item envelope : RightCircularCylinder { @Envelope { source = EnvelopeSource::stated; } :>> radius = 0.09 [m]; :>> height = 0.15 [m]; }
    }

    part def 'DCDC電力段' {
        doc /* 絶縁型コンバータのパワー段。powerDraw は定格負荷時の損失。 */
        attribute mass :> ISQ::mass default 1.5 [kg];
        attribute '消費電力' : PowerValue default 30.0 [W];
        attribute efficiency : Real default 0.95;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.1 [m]; :>> height = 0.04 [m]; }
    }

    part def '出力フィルタ型' {
        doc /* 出力 LC フィルタと逆接保護。 */
        attribute mass :> ISQ::mass default 0.6 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute 'リップルmV' : Real default 50.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.08 [m]; :>> height = 0.05 [m]; }
    }

    part def 'バス終端抵抗' {
        doc /* CAN バス端の 120 オーム分割終端。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '抵抗Ohm' : Real default 120.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.01 [m]; :>> height = 0.01 [m]; }
    }

    part def 'ハーネス区間' {
        doc /* バスのツイストペアハーネス。 */
        attribute mass :> ISQ::mass default 0.8 [kg];
        attribute 'ハーネス長' : LengthValue default 12 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.5 [m]; :>> width = 0.02 [m]; :>> height = 0.02 [m]; }
    }

    part def 'ラジエータコア' {
        doc /* アルミろう付けラジエータコア。 */
        attribute mass :> ISQ::mass default 28.0 [kg];
        attribute '前面投影面積' : AreaValue default 0.8 [m * m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.08 [m]; :>> width = 0.95 [m]; :>> height = 0.85 [m]; }
    }

    part def 'エンジンファン' {
        doc /* ビスカスカップリング式エンジンファン。 */
        attribute mass :> ISQ::mass default 11.0 [kg];
        attribute diameter : LengthValue default 0.75 [m];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.75 [m]; :>> height = 0.75 [m]; }
    }

    part def 'インタークーラ型' {
        doc /* 空冷式インタークーラ。 */
        attribute mass :> ISQ::mass default 16.0 [kg];
        attribute effectiveness : Real default 0.9;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.95 [m]; :>> height = 0.75 [m]; }
    }

    part def '熱交換器ファン' {
        doc /* 計算機用熱交換器のブラシレスファン。 */
        attribute mass :> ISQ::mass default 1.2 [kg];
        attribute '消費電力' : PowerValue default 60.0 [W];
        attribute '風量m3h' : Real default 1200.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.25 [m]; :>> height = 0.25 [m]; }
    }

    part def '冷却水リザーバ' {
        doc /* 計算機冷却ループのリザーバ（液面センサ付き）。 */
        attribute mass :> ISQ::mass default 1.5 [kg];
        attribute '容積L' : Real default 2.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.1 [m]; :>> height = 0.12 [m]; }
    }

    part def '冷却水温センサ' {
        doc /* 冷却液温度センサ（NTC）。 */
        attribute mass :> ISQ::mass default 0.03 [kg];
        attribute '消費電力' : PowerValue default 0.01 [W];
        attribute '精度C' : Real default 0.5;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.03 [m]; :>> width = 0.015 [m]; :>> height = 0.015 [m]; }
    }

    part def 'モデムチップ' {
        doc /* 5G NR モデムチップ。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 4.0 [W];
        attribute '周波数帯数' : Integer default 40;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.02 [m]; :>> height = 0.002 [m]; }
    }

    part def '携帯通信アンテナ' {
        doc /* 屋根上のシャークフィン型セルラアンテナ素子。 */
        attribute mass :> ISQ::mass default 0.1 [kg];
        attribute '利得dBi' : Real default 3.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.04 [m]; :>> height = 0.06 [m]; }
    }

    part def '映像エンコーダ' {
        doc /* 遠隔監視映像用の低遅延 H.265 エンコーダ。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '消費電力' : PowerValue default 8.0 [W];
        attribute '符号化遅れ' : DurationValue default 0.04 [s];
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.05 [m]; :>> height = 0.01 [m]; }
    }

    part def 'ITS無線機' {
        doc /* 760 MHz 帯 ITS 無線機（路車間、車車間通信）。 */
        attribute mass :> ISQ::mass default 0.3 [kg];
        attribute '消費電力' : PowerValue default 6.0 [W];
        attribute '搬送波MHz' : Real default 760.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.08 [m]; :>> height = 0.03 [m]; }
    }

    part def 'DSRCモジュール' {
        doc /* 5.8 GHz DSRC 通信モジュール（ETC 2.0 車載器）。 */
        attribute mass :> ISQ::mass default 0.25 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute '搬送波MHz' : Real default 5800.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.07 [m]; :>> height = 0.025 [m]; }
    }

    part def 'パッチアンテナ' {
        doc /* ITS / DSRC 用パッチアンテナ。 */
        attribute mass :> ISQ::mass default 0.05 [kg];
        attribute '利得dBi' : Real default 5.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.06 [m]; :>> width = 0.06 [m]; :>> height = 0.01 [m]; }
    }

    part def '記録装置ストレージ' {
        doc /* 記録用の産業グレード eMMC と SD カード。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute '容量GiB' : Real default 128.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.015 [m]; :>> height = 0.002 [m]; }
    }

    part def '3軸加速度計' {
        doc /* 3 軸加速度センサ（急ブレーキ、衝撃の記録）。 */
        attribute mass :> ISQ::mass default 0.01 [kg];
        attribute '消費電力' : PowerValue default 0.05 [W];
        attribute '測定範囲G' : Real default 16.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.01 [m]; :>> width = 0.01 [m]; :>> height = 0.003 [m]; }
    }

    part def 'ドライブレコーダカメラ' {
        doc /* ドライブレコーダカメラ（前方、車内）。 */
        attribute mass :> ISQ::mass default 0.15 [kg];
        attribute '消費電力' : PowerValue default 3.0 [W];
        attribute 'フレームレートHz' : Real default 30.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.07 [m]; :>> width = 0.05 [m]; :>> height = 0.05 [m]; }
    }

    part def '電子ヒューズ' {
        doc /* 半導体ヒューズ（eFuse）チャネル。電流を検出し、マイクロ秒で遮断して LIN で状態を報告する。 */
        attribute mass :> ISQ::mass default 0.02 [kg];
        attribute '消費電力' : PowerValue default 0.5 [W];
        attribute '遮断電流' : ElectricCurrentValue default 30 [A];
        attribute '遮断時間' : DurationValue default 5e-05 [s];
        port '負荷側' : '24V電源ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.02 [m]; :>> width = 0.015 [m]; :>> height = 0.005 [m]; }
    }

    /* ------------------------------------------------------------ */
    /* 共通アセンブリ */
    /* ------------------------------------------------------------ */

    part def 'ECU基板' {
        doc /* ECU 基板：ロックステップ MCU、CAN FD トランシーバ 2 個、PMIC、フラッシュ、ウィンドウウォッチドッグ、温度センサ。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "FR4 board"; finish = Finish::pcb; color = "#1e4a32"; }
        part 'マイコン' : 'マイコン型';
        part 'A系CANトランシーバ' : 'CAN_FDトランシーバ';
        part 'B系CANトランシーバ' : 'CAN_FDトランシーバ';
        part '電源管理IC' : '電源管理IC型';
        part 'フラッシュ' : 'フラッシュメモリ';
        part 'ウォッチドッグ' : 'ウィンドウウォッチドッグ';
        part '温度センサ' : '基板温度センサ';
        attribute '基板質量' : MassValue default 0.03 [kg];
        attribute mass :> ISQ::mass = '基板質量' + 'マイコン'.mass + 'A系CANトランシーバ'.mass + 'B系CANトランシーバ'.mass + '電源管理IC'.mass + 'フラッシュ'.mass + 'ウォッチドッグ'.mass + '温度センサ'.mass;
        attribute '消費電力' : PowerValue = 'マイコン'.'消費電力' + 'A系CANトランシーバ'.'消費電力' + 'B系CANトランシーバ'.'消費電力' + '電源管理IC'.'消費電力' + 'フラッシュ'.'消費電力' + 'ウォッチドッグ'.'消費電力' + '温度センサ'.'消費電力';
    }

    part def 'センサ処理部' {
        doc /* センサヘッドの処理基板：FPGA、Ethernet PHY、PMIC。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "FR4 board"; finish = Finish::pcb; color = "#1e4a32"; }
        part 'FPGA' : 'FPGA型';
        part 'Ethernet_PHY' : 'Ethernet_PHY型';
        part '電源管理IC' : '電源管理IC型';
        attribute mass :> ISQ::mass = 0.02 [kg] + 'FPGA'.mass + 'Ethernet_PHY'.mass + '電源管理IC'.mass;
        attribute '消費電力' : PowerValue = 'FPGA'.'消費電力' + 'Ethernet_PHY'.'消費電力' + '電源管理IC'.'消費電力';
    }

    part def 'モータインバータ' {
        doc /* EPS インバータ（巻線 1 組分）：ゲートドライバ、MOSFET 6 個、相電流シャント 3 個、DC リンクコンデンサ、温度センサ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ゲートドライバ' : 'ゲートドライバ型';
        part '上側MOSFET_A相' : 'パワーMOSFET';
        part '下側MOSFET_A相' : 'パワーMOSFET';
        part '上側MOSFET_B相' : 'パワーMOSFET';
        part '下側MOSFET_B相' : 'パワーMOSFET';
        part '上側MOSFET_C相' : 'パワーMOSFET';
        part '下側MOSFET_C相' : 'パワーMOSFET';
        part 'A相シャント' : '電流シャント';
        part 'B相シャント' : '電流シャント';
        part 'C相シャント' : '電流シャント';
        part 'DCリンク' : 'DCリンクコンデンサ';
        part '温度センサ' : '基板温度センサ';
        port '相出力' : '相電力ポート';
        port 'ゲート' : ~'ゲート指令ポート';
        attribute mass :> ISQ::mass = 0.2 [kg] + 'ゲートドライバ'.mass + '上側MOSFET_A相'.mass + '下側MOSFET_A相'.mass + '上側MOSFET_B相'.mass + '下側MOSFET_B相'.mass + '上側MOSFET_C相'.mass + '下側MOSFET_C相'.mass + 'A相シャント'.mass + 'B相シャント'.mass + 'C相シャント'.mass + 'DCリンク'.mass + '温度センサ'.mass;
        attribute '消費電力' : PowerValue = 'ゲートドライバ'.'消費電力' + '上側MOSFET_A相'.'消費電力' + '下側MOSFET_A相'.'消費電力' + '上側MOSFET_B相'.'消費電力' + '下側MOSFET_B相'.'消費電力' + '上側MOSFET_C相'.'消費電力' + '下側MOSFET_C相'.'消費電力' + 'A相シャント'.'消費電力' + 'B相シャント'.'消費電力' + 'C相シャント'.'消費電力' + 'DCリンク'.'消費電力' + '温度センサ'.'消費電力';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; }
    }

    part def 'モジュレータ系統' {
        doc /*
         * モジュレータの 1 チャネル：給気弁、排気弁、バックアップ弁、リレーピストン、冗長圧力センサ 2 個。
         * 応答時間は給気弁の切替、リレーピストン、配管遅れの和。
         */
        @Placement { mode = LayoutMode::connectivity; }
        part '吸気弁' : '電磁弁';
        part '排気バルブ' : '電磁弁';
        part 'バックアップ弁' : '電磁弁' { doc /* コイル無通電時に冗長回路からの空圧バックアップ経路を開く。 */ }
        part 'リレー' : 'リレーピストン';
        part 'A系圧力センサ' : 'ブレーキ圧センサ';
        part 'B系圧力センサ' : 'ブレーキ圧センサ';
        attribute '線路遅延' : DurationValue default 0.005 [s];
        attribute '応答時間' : DurationValue = '吸気弁'.'切替時間' + 'リレー'.'応答時間' + '線路遅延';
        attribute mass :> ISQ::mass = '吸気弁'.mass + '排気バルブ'.mass + 'バックアップ弁'.mass + 'リレー'.mass + 'A系圧力センサ'.mass + 'B系圧力センサ'.mass;
        attribute '消費電力' : PowerValue = '吸気弁'.'消費電力' + '排気バルブ'.'消費電力' + 'A系圧力センサ'.'消費電力' + 'B系圧力センサ'.'消費電力';
    }

    /* ------------------------------------------------------------ */
    /* キャブ（キャブオーバー、チルトキャブ） */
    /* ------------------------------------------------------------ */

    part def 'キャブロックユニット' {
        doc /* キャブロック 1 か所分：機械式ラッチと施錠検知センサ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ロック' : 'キャブロック';
        part 'センサ部' : 'ロックセンサ';
        attribute mass :> ISQ::mass = 'ロック'.mass + 'センサ部'.mass;
        attribute '消費電力' : PowerValue = 'センサ部'.'消費電力';
    }

    part def 'キャブチルト装置' {
        doc /*
         * 電動油圧式キャブチルト装置（フレーム前端に取り付く）。前方の支点まわりにキャブを約 45 度前傾させ、
         * エンジン整備の開口を作る。キャブロック 2 か所の施錠を確認してから走行を許す。
         */
        @Placement { mode = LayoutMode::fixed; }
        attribute 'チルト角deg' : Real default 45.0;
        part 'ポンプ' : 'チルトポンプ' { @Placement { xM = -0.015; yM = 0.3; zM = 0.0; } }
        part '左シリンダ' : 'チルトシリンダ' { @Placement { xM = 0.135; yM = 0.62; zM = 0.0; } }
        part '右シリンダ' : 'チルトシリンダ' { @Placement { xM = 0.135; yM = -0.62; zM = 0.0; } }
        part '左ロック' : 'キャブロックユニット' { @Placement { xM = -0.115; yM = 0.85; zM = 0.15; } }
        part '右ロック' : 'キャブロックユニット' { @Placement { xM = -0.115; yM = -0.85; zM = 0.15; } }
        interface '左チルト油圧' : '油圧配管' connect 'ポンプ' ::> 'ポンプ'.'作動油出口' to 'アクチュエータ' ::> '左シリンダ'.'作動油入口';
        interface '右チルト油圧' : '油圧配管' connect 'ポンプ' ::> 'ポンプ'.'作動油出口' to 'アクチュエータ' ::> '右シリンダ'.'作動油入口';
        attribute mass :> ISQ::mass = 'ポンプ'.mass + '左シリンダ'.mass + '右シリンダ'.mass + '左ロック'.mass + '右ロック'.mass;
        attribute '消費電力' : PowerValue = 'ポンプ'.'消費電力' + '左ロック'.'消費電力' + '右ロック'.'消費電力';
    }

    part def 'エアサスペンションシート' {
        doc /* エアサスペンションシート：フレーム、エアばね、ヒータ、プリテンショナ、着座センサ。 */
        @Placement { mode = LayoutMode::fixed; }
        @Material { name = "woven seat fabric"; finish = Finish::polymer; color = "#2a2e33"; }
        part 'シートフレーム' : 'シートフレーム型' { @Placement { xM = 0.0; yM = -0.05; zM = 0.1; } }
        part 'エアばね' : 'シートエアばね' { @Placement { xM = 0.0; yM = 0.0; zM = -0.42; } }
        part 'ヒータ' : 'シートヒータ' { @Placement { xM = 0.0; yM = -0.05; zM = -0.33; } }
        part 'プリテンショナ' : 'シートベルトプリテンショナ' { @Placement { xM = 0.0; yM = 0.25; zM = 0.3; } }
        part '着座センサ' : '着座センサ型' { @Placement { xM = 0.0; yM = -0.05; zM = -0.31; } }
        attribute mass :> ISQ::mass = 'シートフレーム'.mass + 'エアばね'.mass + 'ヒータ'.mass + 'プリテンショナ'.mass + '着座センサ'.mass;
        attribute '消費電力' : PowerValue = 'ヒータ'.'消費電力' + 'プリテンショナ'.'消費電力' + '着座センサ'.'消費電力';
    }

    part def 'ステアリングコラム型' {
        doc /* 右ハンドルのステアリングコラム：ホイール、コラムスイッチ、クロックスプリング、冗長舵角センサ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ステアリングホイール' : 'ステアリングホイール型';
        part 'コラムスイッチ' : 'コラムスイッチ型';
        part 'クロックスプリング' : 'クロックスプリング型';
        part '舵角センサ' : '舵角センサ型';
        attribute 'チルト範囲deg' : Real default 30.0;
        attribute mass :> ISQ::mass = 4.5 [kg] + 'ステアリングホイール'.mass + 'コラムスイッチ'.mass + 'クロックスプリング'.mass + '舵角センサ'.mass;
        attribute '消費電力' : PowerValue = 'コラムスイッチ'.'消費電力' + '舵角センサ'.'消費電力';
    }

    part def 'ペダルボックス' {
        doc /* ペダルボックス：二重系アクセルペダルセンサと 2 回路フットブレーキバルブ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'アクセル' : 'アクセルペダルセンサ';
        part 'フットバルブ' : 'フットブレーキバルブ';
        part 'A系ブレーキスイッチ' : 'ブレーキ圧センサ';
        part 'B系ブレーキスイッチ' : 'ブレーキ圧センサ';
        attribute mass :> ISQ::mass = 1.5 [kg] + 'アクセル'.mass + 'フットバルブ'.mass + 'A系ブレーキスイッチ'.mass + 'B系ブレーキスイッチ'.mass;
        attribute '消費電力' : PowerValue = 'アクセル'.'消費電力' + 'A系ブレーキスイッチ'.'消費電力' + 'B系ブレーキスイッチ'.'消費電力';
    }

    part def '右ハンドル運転操作装置' {
        doc /*
         * 右ハンドル（RHD）の運転操作装置。無人運行（L4）中は使わないが、物流拠点の構内移動と
         * 点検整備のため人が運転できる状態を保つ。左側通行で運転席は右側（y 負側）。
         */
        @Placement { mode = LayoutMode::fixed; }
        part 'ステアリングコラム' : 'ステアリングコラム型' { @Placement { xM = -0.0575; yM = -0.0875; zM = 0.32; } }
        part 'ペダル' : 'ペダルボックス' { @Placement { xM = 0.2425; yM = -0.0875; zM = -0.3; } }
        part 'セレクタ' : 'シフトセレクタ' { @Placement { xM = -0.3075; yM = 0.3925; zM = -0.08; } }
        part '駐車ブレーキスイッチ' : '駐車ブレーキスイッチ型' { @Placement { xM = -0.0075; yM = 0.2725; zM = 0.12; } }
        part 'リターダレバー' : 'リターダレバー型' { @Placement { xM = 0.0425; yM = -0.4175; zM = 0.37; } }
        attribute mass :> ISQ::mass = 'ステアリングコラム'.mass + 'ペダル'.mass + 'セレクタ'.mass + '駐車ブレーキスイッチ'.mass + 'リターダレバー'.mass;
        attribute '消費電力' : PowerValue = 'ステアリングコラム'.'消費電力' + 'ペダル'.'消費電力' + 'セレクタ'.'消費電力' + '駐車ブレーキスイッチ'.'消費電力' + 'リターダレバー'.'消費電力';
    }

    part def 'メータクラスタ型' {
        doc /* メータクラスタ：表示器と制御基板。速度、警告、自動運転モードを表示する。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        part '基板' : 'ECU基板';
        part 'ディスプレイ' : 'メータディスプレイ';
        attribute mass :> ISQ::mass = 0.6 [kg] + '基板'.mass + 'ディスプレイ'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'ディスプレイ'.'消費電力';
    }

    part def 'キャブHMI' {
        doc /*
         * キャブ HMI：メータ、センタディスプレイ、外部向け自動運転作動表示灯（左右）、ブザー、引継ぎスイッチ、
         * 非常停止スイッチ、車内監視カメラ。遠隔監視センターの指示もセンタディスプレイに出す。
         */
        @Placement { mode = LayoutMode::fixed; }
        part 'メータクラスタ' : 'メータクラスタ型' { @Placement { xM = -0.0425; yM = -0.205; zM = -0.205; } }
        part 'センターディスプレイ' : 'センターディスプレイ型' { @Placement { xM = -0.0925; yM = 0.295; zM = -0.255; } }
        part '左自動運行表示灯' : '自動運行表示灯' { @Placement { xM = 0.0775; yM = 0.245; zM = 0.415; } }
        part '右自動運行表示灯' : '自動運行表示灯' { @Placement { xM = 0.0775; yM = -0.655; zM = 0.415; } }
        part 'ブザー' : 'ブザー型' { @Placement { xM = -0.0425; yM = -0.425; zM = -0.305; } }
        part '引継ぎボタン' : '引継ぎボタン型' { @Placement { xM = -0.0925; yM = 0.075; zM = -0.405; } }
        part '非常停止スイッチ' : '非常停止スイッチ型' { @Placement { xM = -0.0925; yM = 0.645; zM = -0.405; } }
        part 'ドライバモニタ' : 'ドライバモニタカメラ' { @Placement { xM = 0.0075; yM = -0.305; zM = 0.245; } }
        attribute mass :> ISQ::mass = 'メータクラスタ'.mass + 'センターディスプレイ'.mass + '左自動運行表示灯'.mass + '右自動運行表示灯'.mass + 'ブザー'.mass + '引継ぎボタン'.mass + '非常停止スイッチ'.mass + 'ドライバモニタ'.mass;
        attribute '消費電力' : PowerValue = 'メータクラスタ'.'消費電力' + 'センターディスプレイ'.'消費電力' + '左自動運行表示灯'.'消費電力' + '右自動運行表示灯'.'消費電力' + 'ブザー'.'消費電力' + '引継ぎボタン'.'消費電力' + '非常停止スイッチ'.'消費電力' + 'ドライバモニタ'.'消費電力';
        port '24V電源' : ~'24V電源ポート' { in :>> current = 1.5 [A]; }
        port 'CAN' : 'CANポート' { :>> '負荷率' = 0.05; }
        @Budget { powerW = 36.0; bus = "lv24a"; }
        @Safety { asil = Asil::QM; isolationGroup = "body"; }
    }

    part def 'キャブ空調' {
        doc /* キャブ空調：コンプレッサ、エバポレータ、コンデンサ、ブロワ。計算機ラック周辺も 45 C 以下に保つ。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '冷却能力' : PowerValue default 5 [kW];
        part 'コンプレッサ' : 'エアコンコンプレッサ';
        part 'エバポレータ' : 'エバポレータ型';
        part 'コンデンサ' : 'コンデンサ型';
        part 'ブロワ' : 'ブロワ型';
        attribute mass :> ISQ::mass = 6 [kg] + 'コンプレッサ'.mass + 'エバポレータ'.mass + 'コンデンサ'.mass + 'ブロワ'.mass;
        attribute '消費電力' : PowerValue = 'ブロワ'.'消費電力';
        @Budget { powerW = 150.0; bus = "lv24a"; }
    }

    part def 'センサ洗浄装置型' {
        doc /* センサ洗浄系：ウォッシャポンプ、洗浄液タンク、LiDAR 窓のエアナイフ 4 個。ノズルは各センサ側に付く。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ポンプ' : 'ウォッシャポンプ';
        part 'タンク' : 'ウォッシャタンク';
        part 'エアナイフ群' : 'エアナイフ'[4];
        attribute mass :> ISQ::mass = 'ポンプ'.mass + 'タンク'.mass + 4 * 'エアナイフ群'.mass;
        attribute '消費電力' : PowerValue = 'ポンプ'.'消費電力';
        @Budget { powerW = 40.0; bus = "lv24a"; }
    }

    part def 'キャブオーバーキャブ' {
        doc /*
         * 大型キャブオーバーのフルキャブ（チルトキャブ）。前面は平らで、キャブが前軸の真上に載る。
         * 幅 2.49 m、全長 2.35 m、シェル下端は地上 1.0 m（バンパとステップはフレーム側）、床面は地上約 1.45 m、屋根上にエアデフレクタ。右ハンドル。
         * 中空のシェルの中に座席、運転操作装置、HMI、空調、センサ洗浄系、仮眠ベッドを収め、
         * 自動運転計算機ラックと運行記録計もキャブ内に置く。キャブチルト時は前方下端の支点で前傾する。
         */
        @Material { name = "pressed steel cab, white paint"; finish = Finish::paint; color = "#eef0f1"; roughness = 0.3; }
        attribute 'キャブ長' : LengthValue default 2.35 [m];
        attribute 'キャブ幅' : LengthValue default 2.49 [m];
        attribute '外殻高さ' : LengthValue default 2.15 [m];
        attribute '外形高さ' : LengthValue default 2.6 [m];
        attribute 'デフレクタ高さ' : LengthValue default 0.45 [m];
        attribute '床面地上高' : LengthValue default 1.45 [m];
        attribute '外殻質量' : MassValue default 1050 [kg];
        part '運転席' : 'エアサスペンションシート' { @Placement { xM = -0.195; yM = -0.6; zM = -0.35; } }
        part '助手席' : 'エアサスペンションシート' { @Placement { xM = -0.195; yM = 0.6; zM = -0.35; } }
        part '仮眠ベッド' : '仮眠ベッド型' { @Placement { xM = -0.865; yM = 0.0; zM = 0.0; } }
        part '運転操作装置' : '右ハンドル運転操作装置' { @Placement { xM = 0.5925; yM = -0.5125; zM = -0.37; } }
        part 'HMI' : 'キャブHMI' { @Placement { xM = 1.0275; yM = 0.355; zM = 0.555; } }
        part '空調' : 'キャブ空調' { @Placement { xM = -0.315; yM = 0.0; zM = 1.05; } }
        part 'センサ洗浄装置' : 'センサ洗浄装置型' { @Placement { xM = 0.785; yM = 0.85; zM = -1.0; } }
        part '計算機' : '自動運転計算機ラック' { @Placement { xM = -0.865; yM = 0.0; zM = -1.0; } }
        part '記録装置' : '運行記録装置' { @Placement { xM = 0.685; yM = 0.4; zM = -0.2; } }
        attribute mass :> ISQ::mass = '外殻質量' + '運転席'.mass + '助手席'.mass + '仮眠ベッド'.mass + '運転操作装置'.mass + 'HMI'.mass + '空調'.mass + 'センサ洗浄装置'.mass + '計算機'.mass + '記録装置'.mass;
        attribute '消費電力' : PowerValue = '運転席'.'消費電力' + '助手席'.'消費電力' + '運転操作装置'.'消費電力' + 'HMI'.'消費電力' + '空調'.'消費電力' + 'センサ洗浄装置'.'消費電力';
        item envelope : RectangularCuboid {
            @Envelope { source = EnvelopeSource::computed; hollow = true; wallThicknessM = 0.004; rule = "キャブ全長 x キャブ幅 x（シェル高さ + エアデフレクタ）"; }
            :>> length = 'キャブ長';
            :>> width = 'キャブ幅';
            :>> height = '外殻高さ' + 'デフレクタ高さ';
        }
        item shell : Loft {
            doc /* 後壁から前面まで：角張った後壁、屋根、わずかに傾いた前面ガラス、平らな前面。 */
            item '後壁' : Section { :>> station = -'キャブ長' / 2; :>> width = 'キャブ幅' * 0.97; :>> height = '外殻高さ' * 0.98; :>> cv = -'デフレクタ高さ' / 2 - '外殻高さ' * 0.01; :>> exponent = 6.0; }
            item 'ルーフ後部' : Section { :>> station = -'キャブ長' / 2 + 0.3 [m]; :>> width = 'キャブ幅'; :>> height = '外殻高さ'; :>> cv = -'デフレクタ高さ' / 2; :>> exponent = 6.0; }
            item 'ウインドシールド上部' : Section { :>> station = 'キャブ長' / 2 - 0.12 [m]; :>> width = 'キャブ幅'; :>> height = '外殻高さ'; :>> cv = -'デフレクタ高さ' / 2; :>> exponent = 6.0; }
            item 'フロントフェイス' : Section { :>> station = 'キャブ長' / 2; :>> width = 'キャブ幅' * 0.98; :>> height = '外殻高さ' * 0.96; :>> cv = -'デフレクタ高さ' / 2 - '外殻高さ' * 0.02; :>> exponent = 5.0; }
        }
        item 'ルーフデフレクタ' : Loft {
            doc /* 屋根上のエアデフレクタ。荷箱の前面高さまで風を導く。 */
            :>> z = '外殻高さ' / 2 - 'デフレクタ高さ' / 2;
            item rear : Section { :>> station = -'キャブ長' / 2 + 0.1 [m]; :>> width = 'キャブ幅' * 0.94; :>> height = 'デフレクタ高さ'; :>> cv = 'デフレクタ高さ' / 2; :>> exponent = 4.0; }
            item front : Section { :>> station = 0.45 [m]; :>> width = 'キャブ幅' * 0.8; :>> height = 0.04 [m]; :>> cv = 0.02 [m]; :>> exponent = 4.0; }
        }
        item windscreen : Block {
            doc /* 前面ガラス（わずかに傾斜）。 */
            :>> x = 'キャブ長' / 2 - 0.03 [m];
            :>> z = 0.25 [m];
            :>> pitchDeg = -6.0;
            :>> length = 0.03 [m];
            :>> width = 'キャブ幅' * 0.88;
            :>> height = 0.95 [m];
        }
        item 'グリル' : Grille {
            :>> face = Face::front;
            :>> u = 0.5 [m];
            :>> v = 0.12 [m];
            :>> width = 1.5 [m];
            :>> height = 0.4 [m];
            :>> holeShape = HoleShape::slot;
            :>> holeSize = 0.02 [m];
            :>> pitch = 0.05 [m];
        }
        item 'ヘッドランプ' : Block {
            doc /* ヘッドランプ（左右、前面下部）。 */
            :>> x = 'キャブ長' / 2 - 0.02 [m];
            :>> y = 0.95 [m];
            :>> z = -1.08 [m];
            :>> length = 0.04 [m];
            :>> width = 0.36 [m];
            :>> height = 0.16 [m];
            :>> mirror = MirrorPlane::xz;
        }
        item 'ミラーステー' : Rod {
            doc /* 後写鏡のステー（左右）。 */
            :>> x = 'キャブ長' / 2 - 0.25 [m];
            :>> y = 'キャブ幅' / 2 + 0.05 [m];
            :>> z = 0.25 [m];
            :>> yawDeg = 90.0;
            :>> radius = 0.015 [m];
            :>> length = 0.2 [m];
            :>> mirror = MirrorPlane::xz;
        }
        item 'ミラー' : Block {
            doc /* 後写鏡（左右）。全幅には含めない。 */
            :>> x = 'キャブ長' / 2 - 0.25 [m];
            :>> y = 'キャブ幅' / 2 + 0.16 [m];
            :>> z = 0.2 [m];
            :>> length = 0.06 [m];
            :>> width = 0.22 [m];
            :>> height = 0.42 [m];
            :>> mirror = MirrorPlane::xz;
        }
        item 'ドアハンドル' : Handle {
            :>> face = Face::left;
            :>> u = 0.9 [m];
            :>> v = 0.9 [m];
            :>> width = 0.2 [m];
            :>> height = 0.04 [m];
            :>> label = "キャブドア";
        }
        @Joint { kind = JointKind::revolute; axis = Axis::y; angleDeg = 45.0; xM = 1.0; yM = 0.0; zM = -1.3; }
        @Placement { mode = LayoutMode::fixed; anchor = Anchor::front; }
    }

    /* ------------------------------------------------------------ */
    /* シャシー（ラダーフレームと懸架装置） */
    /* ------------------------------------------------------------ */

    part def 'ECAS制御ユニット' {
        doc /* 電子制御エアサスペンション（ECAS）の ECU。車高を一定に保ち、荷役時の車高調整も行う。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        part '基板' : 'ECU基板';
        part 'バルブドライバ' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 0.4 [kg] + '基板'.mass + 'バルブドライバ'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'バルブドライバ'.'消費電力';
        port 'CAN' : 'CANポート' { :>> '負荷率' = 0.05; }
    }

    part def 'はしご形フレーム' {
        doc /*
         * 走行シャシー（ローリングシャシー）。はしご形フレームは高張力鋼の C 形断面サイドレール 2 本
         * （外幅 850 mm、上面は地上 1.0 m）とクロスメンバ 8 本。前 2 軸（板ばね）と後 2 軸（エアサス）を
         * 吊り、前端にキャブチルト装置、前バンパ、乗降ステップ、側方の巻き込み防止装置、後部突入防止装置を持つ。
         * ECAS（電子制御エアサス）の ECU と電磁弁ブロックはフレーム中央に付く。
         */
        @Placement { mode = LayoutMode::fixed; }
        @Material { name = "high tensile steel rails, black e-coat"; finish = Finish::paint; color = "#1f2124"; roughness = 0.6; }
        attribute 'フレーム長' : LengthValue default 11.84 [m];
        attribute 'フレーム幅' : LengthValue default 0.85 [m];
        attribute 'レール深さ' : LengthValue default 0.28 [m];
        attribute 'フレーム質量' : MassValue default 1400 [kg];
        attribute 'ガード質量' : MassValue default 115 [kg];
        part '第1軸' : '操舵軸' { @Placement { xM = 4.52; yM = 0; zM = 0.0; } }
        part '第2軸' : '操舵軸' { @Placement { xM = 2.72; yM = 0; zM = 0.0; } }
        part '後前軸' : '前側駆動軸' { @Placement { xM = -2.08; yM = 0; zM = 0.0; } }
        part '後後軸' : '駆動軸' { @Placement { xM = -3.38; yM = 0; zM = 0.0; } }
        part 'キャブチルト' : 'キャブチルト装置' { @Placement { xM = 5.615; yM = 0.0; zM = 0.25; } }
        part 'ECAS' : 'ECAS制御ユニット' { @Placement { xM = 0.13; yM = 0.3; zM = 0.38; } }
        part '車高調整バルブ' : '車高調整バルブブロック' { @Placement { xM = 0.13; yM = -0.3; zM = 0.38; } }
        interface '前左ばね取付' : 'エア配管' connect '供給' ::> '車高調整バルブ'.'空気出口' to '送出' ::> '後前軸'.'左エアばね'.'空気入口';
        interface '前右ばね取付' : 'エア配管' connect '供給' ::> '車高調整バルブ'.'空気出口' to '送出' ::> '後前軸'.'右エアばね'.'空気入口';
        interface '後左ばね取付' : 'エア配管' connect '供給' ::> '車高調整バルブ'.'空気出口' to '送出' ::> '後後軸'.'左エアばね'.'空気入口';
        interface '後右ばね取付' : 'エア配管' connect '供給' ::> '車高調整バルブ'.'空気出口' to '送出' ::> '後後軸'.'右エアばね'.'空気入口';
        port '空気供給' : ~'空気ポート';
        attribute 'フレーム組立質量' : MassValue = 'フレーム質量' + 'ガード質量' + 'キャブチルト'.mass + 'ECAS'.mass + '車高調整バルブ'.mass;
        attribute mass :> ISQ::mass = 'フレーム組立質量' + '第1軸'.mass + '第2軸'.mass + '後前軸'.mass + '後後軸'.mass;
        attribute '消費電力' : PowerValue = 'キャブチルト'.'消費電力' + 'ECAS'.'消費電力' + '車高調整バルブ'.'消費電力' + '後前軸'.'消費電力' + '後後軸'.'消費電力';
        port '操舵軸ハンガ' : '車軸取付ポート'[2] { in :>> axleLoad = 52000 [N]; }
        port '後2軸ハンガ' : '車軸取付ポート'[2];
        port 'ボデー取付部' : 'ボデー取付ポート';
        item envelope : RectangularCuboid {
            @Envelope { source = EnvelopeSource::computed; rule = "フレーム長 x 車軸の全幅 x 地面からフレーム上面まで"; }
            :>> length = 'フレーム長';
            :>> width = 2.49 [m];
            :>> height = 1.0 [m];
        }
        item 'サイドレール' : Block {
            doc /* サイドレール 2 本（左右対称）。 */
            :>> y = 'フレーム幅' / 2 - 0.05 [m];
            :>> z = 0.36 [m];
            :>> length = 'フレーム長' - 0.3 [m];
            :>> x = -0.15 [m];
            :>> width = 0.1 [m];
            :>> height = 'レール深さ';
            :>> mirror = MirrorPlane::xz;
        }
        item 'クロスメンバ' : Block {
            doc /* クロスメンバ 8 本。 */
            :>> x = 'フレーム長' / 2 - 0.6 [m];
            :>> z = 0.36 [m];
            :>> length = 0.12 [m];
            :>> width = 'フレーム幅' - 0.2 [m];
            :>> height = 'レール深さ' * 0.8;
            :>> count = 8;
            :>> stepX = -('フレーム長' - 0.9 [m]) / 7;
        }
        item 'フロントバンパ' : Block {
            doc /* 前バンパ（前部突入防止装置を兼ね、フレーム前端に付く）。 */
            :>> x = 'フレーム長' / 2 - 0.11 [m];
            :>> z = 0.26 [m];
            :>> length = 0.22 [m];
            :>> width = 2.44 [m];
            :>> height = 0.42 [m];
        }
        item steps : Block {
            doc /* 乗降ステップ（左右、前輪の後ろ）。 */
            :>> x = 3.805 [m];
            :>> y = 1.095 [m];
            :>> z = 0.225 [m];
            :>> length = 0.35 [m];
            :>> width = 0.3 [m];
            :>> height = 0.5 [m];
            :>> mirror = MirrorPlane::xz;
        }
        item 'サイドガード' : Block {
            doc /* 側方の巻き込み防止装置（左右）。 */
            :>> x = -0.37 [m];
            :>> y = 1.12 [m];
            :>> z = 0.1 [m];
            :>> length = 1.9 [m];
            :>> width = 0.03 [m];
            :>> height = 0.25 [m];
            :>> mirror = MirrorPlane::xz;
        }
        item 'リヤアンダーランプロテクタ' : Block {
            doc /* 後部突入防止装置。 */
            :>> x = -5.87 [m];
            :>> z = 0.05 [m];
            :>> length = 0.1 [m];
            :>> width = 2.3 [m];
            :>> height = 0.15 [m];
        }
        item 'テールランプ' : Block {
            doc /* 尾灯、制動灯、方向指示器のコンビネーションランプ（左右）。 */
            :>> x = -5.92 [m];
            :>> y = 0.95 [m];
            :>> z = 0.3 [m];
            :>> length = 0.05 [m];
            :>> width = 0.35 [m];
            :>> height = 0.12 [m];
            :>> mirror = MirrorPlane::xz;
        }
    }

    /* ------------------------------------------------------------ */
    /* 車軸とホイールエンド */
    /* ------------------------------------------------------------ */

    part def 'ディスクブレーキ型' {
        doc /* エアディスクブレーキ：キャリパ、パッド、ベンチレーテッドロータ、摩耗センサ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'キャリパ' : 'ブレーキキャリパ';
        part 'パッド' : 'ブレーキパッド';
        part 'ロータ' : 'ブレーキロータ';
        part '摩耗センサ' : 'パッド摩耗センサ';
        attribute '最大トルクNm' : Real default 22000.0;
        attribute mass :> ISQ::mass = 'キャリパ'.mass + 'パッド'.mass + 'ロータ'.mass + '摩耗センサ'.mass;
    }

    part def 'ドラムブレーキ型' {
        doc /* 後軸のドラムブレーキ：ドラム、シュー、S カム、自動すきま調整装置。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ドラム' : 'ブレーキドラム';
        part 'ブレーキシュー' : 'ブレーキシュー型';
        part 'Sカム' : 'Sカムシャフト';
        part 'スラックアジャスタ' : 'スラックアジャスタ型';
        attribute '最大トルクNm' : Real default 26000.0;
        attribute mass :> ISQ::mass = 'ドラム'.mass + 'ブレーキシュー'.mass + 'Sカム'.mass + 'スラックアジャスタ'.mass;
    }

    part def '操舵軸ホイールエンド' {
        doc /* 前軸のホイールエンド：エアディスクブレーキ、ブレーキチャンバ、車輪速センサ、ハブベアリング。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ディスクブレーキ' : 'ディスクブレーキ型';
        part 'ブレーキチャンバ' : 'ブレーキチャンバ型';
        part '車輪速センサ' : '車輪速センサ型';
        part 'ハブ' : 'ハブベアリング';
        attribute mass :> ISQ::mass = 'ディスクブレーキ'.mass + 'ブレーキチャンバ'.mass + '車輪速センサ'.mass + 'ハブ'.mass;
    }

    part def '駆動軸ホイールエンド' {
        doc /* 後軸のホイールエンド：ドラムブレーキ、スプリングブレーキチャンバ（駐車ブレーキ兼用）、車輪速センサ、ハブ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'ドラムブレーキ' : 'ドラムブレーキ型';
        part 'ブレーキチャンバ' : 'スプリングブレーキチャンバ';
        part '車輪速センサ' : '車輪速センサ型';
        part 'ハブ' : 'ハブベアリング';
        attribute mass :> ISQ::mass = 'ドラムブレーキ'.mass + 'ブレーキチャンバ'.mass + '車輪速センサ'.mass + 'ハブ'.mass;
    }

    part def '車軸型' {
        doc /*
         * 車軸。タイヤは 275/80R22.5（外径約 1.01 m、JATMA 規格の単輪荷重 約 3 t）。wheelsPerSide は前軸 1、後軸 2（ダブルタイヤ）。
         * loadRating は技術上の許容軸重。
         */
        @Material { name = "tyres on steel wheels"; finish = Finish::rubber; color = "#232528"; roughness = 0.85; }
        attribute '許容軸重' : MassValue default 10000 [kg];
        attribute '全幅' : LengthValue default 2.49 [m];
        attribute 'タイヤ半径' : LengthValue default 0.5 [m];
        attribute 'タイヤ幅' : LengthValue default 0.275 [m];
        attribute '片側輪数' : Integer default 2;
        attribute '転がり抵抗係数' : Real default 0.006;
        attribute 'ビーム質量' : MassValue default 300 [kg];
        attribute '車輪質量' : MassValue default 85 [kg];
        attribute '区画長' : LengthValue default 1.0 [m];
        port '取付部' : ~'車軸取付ポート';
        item envelope : RectangularCuboid {
            @Envelope { source = EnvelopeSource::computed; rule = "懸架装置を含む前後長 x 全幅 x タイヤ外径"; }
            :>> length = '区画長';
            :>> width = '全幅';
            :>> height = 'タイヤ半径' * 2;
        }
        item '車軸ビーム' : Rod {
            doc /* 車軸ビーム。 */
            :>> yawDeg = 90.0;
            :>> radius = 0.07 [m];
            :>> length = '全幅' - 'タイヤ幅' * 2;
        }
        item 'タイヤ' : Revolve {
            doc /* タイヤ（左右対称、ダブルタイヤは内側へ並べる）。 */
            :>> yawDeg = 90.0;
            :>> y = '全幅' / 2 - 'タイヤ幅' / 2;
            :>> count = '片側輪数';
            :>> stepY = -('タイヤ幅' + 0.035 [m]);
            :>> mirror = MirrorPlane::xz;
            item tread : Section { :>> width = 'タイヤ幅'; :>> height = 'タイヤ半径' * 0.62; :>> cv = 'タイヤ半径' * 0.69; :>> exponent = 4.0; }
        }
        item 'ホイール' : Revolve {
            doc /* スチールホイール（JIS 方式 8 穴）。 */
            :>> yawDeg = 90.0;
            :>> y = '全幅' / 2 - 'タイヤ幅' / 2;
            :>> count = '片側輪数';
            :>> stepY = -('タイヤ幅' + 0.035 [m]);
            :>> mirror = MirrorPlane::xz;
            item disc : Section { :>> width = 'タイヤ幅' * 0.9; :>> height = 'タイヤ半径' * 0.4; :>> cv = 'タイヤ半径' * 0.2; :>> exponent = 4.0; }
        }
    }

    part def '操舵軸' :> '車軸型' {
        doc /* 前 2 軸（第 1 軸、第 2 軸）の操舵軸。シングルタイヤ、エアディスクブレーキ、テーパリーフスプリング、ショックアブソーバ、スタビライザ。許容軸重 10 t 級。第 2 軸はリレーロッドで第 1 軸に連動する。 */
        @Placement { mode = LayoutMode::fixed; }
        attribute :>> '全幅' = 2.42 [m];
        attribute :>> '片側輪数' = 1;
        attribute :>> 'ビーム質量' = 260 [kg];
        attribute :>> '区画長' = 1.6 [m];
        part '左ホイールエンド' : '操舵軸ホイールエンド' { @Placement { xM = 0.0; yM = 0.85; zM = 0.0; } }
        part '右ホイールエンド' : '操舵軸ホイールエンド' { @Placement { xM = 0.0; yM = -0.85; zM = 0.0; } }
        part '左リーフスプリング' : 'リーフスプリング' { @Placement { xM = 0.0; yM = 0.42; zM = 0.2; } }
        part '右リーフスプリング' : 'リーフスプリング' { @Placement { xM = 0.0; yM = -0.42; zM = 0.2; } }
        part '左ショックアブソーバ' : 'ショックアブソーバ' { @Placement { xM = -0.3; yM = 0.3; zM = 0.25; } }
        part '右ショックアブソーバ' : 'ショックアブソーバ' { @Placement { xM = -0.3; yM = -0.3; zM = 0.25; } }
        part 'スタビライザ' : 'スタビライザ型' { @Placement { xM = -0.62; yM = 0.0; zM = 0.09; } }
        attribute mass :> ISQ::mass = 'ビーム質量' + 2 * '車輪質量' + '左ホイールエンド'.mass + '右ホイールエンド'.mass + '左リーフスプリング'.mass + '右リーフスプリング'.mass + '左ショックアブソーバ'.mass + '右ショックアブソーバ'.mass + 'スタビライザ'.mass;
        port :>> '取付部' { out :>> axleLoad = 52000 [N]; }
        @Safety { asil = Asil::D; isolationGroup = "chassis"; }
    }

    part def '駆動軸' :> '車軸型' {
        doc /* 後 2 軸（2 デフ、8x4 の後輪側）の駆動軸 1 本。ダブルタイヤ、ドラムブレーキ、ハイポイドデフ、エアばね 2 個、ショックアブソーバ、トルクロッド、車高センサ。 */
        @Placement { mode = LayoutMode::fixed; }
        attribute :>> 'ビーム質量' = 330 [kg];
        attribute :>> '区画長' = 1.3 [m];
        attribute '減速比' : Real default 3.9;
        part '左ホイールエンド' : '駆動軸ホイールエンド' { @Placement { xM = 0.0; yM = 0.85; zM = 0.0; } }
        part '右ホイールエンド' : '駆動軸ホイールエンド' { @Placement { xM = 0.0; yM = -0.85; zM = 0.0; } }
        part '終減速機' : '終減速機型' { @Placement { xM = 0.0; yM = 0.0; zM = 0.0; } }
        part '左シャフト' : 'アクスルシャフト' { @Placement { xM = 0.0; yM = 0.39; zM = 0.0; } }
        part '右シャフト' : 'アクスルシャフト' { @Placement { xM = 0.0; yM = -0.39; zM = 0.0; } }
        part '左エアばね' : 'エアばね型' { @Placement { xM = 0.0; yM = 0.55; zM = 0.3; } }
        part '右エアばね' : 'エアばね型' { @Placement { xM = 0.0; yM = -0.55; zM = 0.3; } }
        part '左ショックアブソーバ' : 'ショックアブソーバ' { @Placement { xM = 0.3; yM = 0.3; zM = 0.27; } }
        part '右ショックアブソーバ' : 'ショックアブソーバ' { @Placement { xM = 0.3; yM = -0.3; zM = 0.27; } }
        part '左トルクロッド' : 'トルクロッド' { @Placement { xM = -0.3; yM = 0.35; zM = 0.3; } }
        part '右トルクロッド' : 'トルクロッド' { @Placement { xM = -0.3; yM = -0.35; zM = 0.3; } }
        part '車高センサ' : '車高センサ型' { @Placement { xM = 0.2; yM = 0.0; zM = 0.4; } }
        port '駆動入力' : ~'トルクポート';
        attribute '消費電力' : PowerValue = '車高センサ'.'消費電力';
        attribute mass :> ISQ::mass default 'ビーム質量' + 4 * '車輪質量' + '左ホイールエンド'.mass + '右ホイールエンド'.mass + '終減速機'.mass + '左シャフト'.mass + '右シャフト'.mass + '左エアばね'.mass + '右エアばね'.mass + '左ショックアブソーバ'.mass + '右ショックアブソーバ'.mass + '左トルクロッド'.mass + '右トルクロッド'.mass + '車高センサ'.mass;
        item differential : Ball {
            doc /* デフキャリア。 */
            :>> x = 0.05 [m];
            :>> radius = 0.25 [m];
        }
        @Safety { asil = Asil::C; isolationGroup = "chassis"; }
    }

    part def '前側駆動軸' :> '駆動軸' {
        doc /* 後前軸。軸間デフとデフロックを持ち、後後軸へ動力を通す（スルーシャフト）。 */
        @Placement { mode = LayoutMode::fixed; }
        part '軸間差動装置' : '軸間差動装置型' { @Placement { xM = 0.4; yM = 0.0; zM = 0.0; } }
        part 'デフロック' : 'デフロックアクチュエータ' { @Placement { xM = 0.4; yM = 0.0; zM = 0.2; } }
        port 'スルー出力' : 'トルクポート';
        attribute :>> mass = 'ビーム質量' + 4 * '車輪質量' + '左ホイールエンド'.mass + '右ホイールエンド'.mass + '終減速機'.mass + '左シャフト'.mass + '右シャフト'.mass + '左エアばね'.mass + '右エアばね'.mass + '左ショックアブソーバ'.mass + '右ショックアブソーバ'.mass + '左トルクロッド'.mass + '右トルクロッド'.mass + '車高センサ'.mass + '軸間差動装置'.mass + 'デフロック'.mass;
    }

    /* ------------------------------------------------------------ */
    /* パワートレイン（ディーゼル、AMT、後処理） */
    /* ------------------------------------------------------------ */

    part def 'エンジン制御モジュール' {
        doc /* エンジン制御モジュール（ECM）。J1939 のトルク指令（TSC1）を受けて噴射量を決める。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "die cast aluminium case"; finish = Finish::metal; color = "#7a8088"; roughness = 0.5; }
        attribute 'ループ周期' : DurationValue default 0.01 [s];
        attribute 'トルク応答' : DurationValue default 0.15 [s];
        part '基板' : 'ECU基板';
        part 'インジェクタ駆動バンク1' : 'ゲートドライバ型';
        part 'インジェクタ駆動バンク2' : 'ゲートドライバ型';
        part 'インジェクタ駆動バンク3' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 1.2 [kg] + '基板'.mass + 'インジェクタ駆動バンク1'.mass + 'インジェクタ駆動バンク2'.mass + 'インジェクタ駆動バンク3'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'インジェクタ駆動バンク1'.'消費電力' + 'インジェクタ駆動バンク2'.'消費電力' + 'インジェクタ駆動バンク3'.'消費電力';
        port 'CAN' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.35; }
        @Safety { asil = Asil::C; isolationGroup = "powertrain"; }
    }

    part def 'ターボチャージャ' {
        doc /* 可変ノズルターボ（VGT）。電動ベーンアクチュエータと回転センサ。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '過給圧' : PressureValue default 260000 [Pa];
        part 'VGTアクチュエータ' : '可変ノズルアクチュエータ';
        part '車輪速センサ' : '速度センサ';
        attribute mass :> ISQ::mass = 28 [kg] + 'VGTアクチュエータ'.mass + '車輪速センサ'.mass;
    }

    part def 'コモンレール式燃料噴射装置' {
        doc /* コモンレール噴射系：高圧ポンプ、レール、インジェクタ 6 本（最高 220 MPa）。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute 'レール圧' : PressureValue default 220000000 [Pa];
        part 'ポンプ' : 'サプライポンプ';
        part 'レール' : '燃料レール';
        part 'インジェクタ群' : 'インジェクタ'[6];
        port '燃料入口' : ~'燃料ポート';
        attribute mass :> ISQ::mass = 'ポンプ'.mass + 'レール'.mass + 6 * 'インジェクタ群'.mass;
        attribute '消費電力' : PowerValue = 6 * 'インジェクタ群'.'消費電力';
    }

    part def 'EGR装置' {
        doc /* 排気再循環（EGR）：電動 EGR バルブと水冷 EGR クーラ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '弁' : 'EGRバルブ';
        part 'クーラ' : 'EGRクーラ';
        attribute mass :> ISQ::mass = '弁'.mass + 'クーラ'.mass;
        attribute '消費電力' : PowerValue = '弁'.'消費電力';
    }

    part def '排気ブレーキ型' {
        doc /* 排気ブレーキ：排気管のバタフライ弁を閉じてエンジンの抵抗で減速する。日本の大型車の標準装備。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '弁' : '排気ブレーキバルブ';
        attribute '制動力' : PowerValue default 150 [kW];
        attribute mass :> ISQ::mass = 1.0 [kg] + '弁'.mass;
        attribute '消費電力' : PowerValue = '弁'.'消費電力';
    }

    part def 'ディーゼルエンジン' {
        doc /*
         * 直列 6 気筒 9.8 L コモンレールターボディーゼル（280 kW、1900 N m）。ECM、VGT ターボ、コモンレール、EGR、
         * 排気ブレーキ、スタータ。キャブの下、前軸の真上に縦置きで載る（キャブオーバー）。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "cast iron block, painted"; finish = Finish::paint; color = "#3b4046"; roughness = 0.55; }
        attribute '排気量' : VolumeValue default 0.0098 [m^3];
        attribute '定格出力' : PowerValue default 280 [kW];
        attribute '最大トルク瞬時Nm' : Real default 1900.0;
        attribute 'ブロック質量' : MassValue default 700 [kg];
        part 'ECM' : 'エンジン制御モジュール' { @Placement { xM = 0.0; yM = 0.47; zM = 0.1; } }
        part 'ターボ' : 'ターボチャージャ' { @Placement { xM = -0.3; yM = -0.45; zM = 0.3; } }
        part '燃料噴射装置' : 'コモンレール式燃料噴射装置' { @Placement { xM = 0.05; yM = 0.3; zM = 0.35; } }
        part 'EGR' : 'EGR装置' { @Placement { xM = 0.1; yM = -0.35; zM = 0.4; } }
        part '排気ブレーキ' : '排気ブレーキ型' { @Placement { xM = -0.55; yM = -0.4; zM = -0.1; } }
        part 'スタータ' : 'スタータモータ' { @Placement { xM = -0.5; yM = 0.3; zM = -0.35; } }
        part 'クランク角センサ' : '速度センサ';
        part 'カムセンサ' : '速度センサ';
        attribute mass :> ISQ::mass = 'ブロック質量' + 'ECM'.mass + 'ターボ'.mass + '燃料噴射装置'.mass + 'EGR'.mass + '排気ブレーキ'.mass + 'スタータ'.mass + 'クランク角センサ'.mass + 'カムセンサ'.mass;
        attribute '消費電力' : PowerValue = 'ECM'.'消費電力' + '燃料噴射装置'.'消費電力' + 'EGR'.'消費電力' + '排気ブレーキ'.'消費電力' + 'クランク角センサ'.'消費電力' + 'カムセンサ'.'消費電力';
        port 'クランク出力' : 'トルクポート';
        port '排気出口' : '排気ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 1.3 [m]; :>> width = 0.8 [m]; :>> height = 1.05 [m]; }
        item engineBlock : Block {
            doc /* シリンダブロックとヘッド。 */
            :>> length = 1.2 [m];
            :>> width = 0.7 [m];
            :>> height = 0.95 [m];
        }
        @Safety { asil = Asil::C; isolationGroup = "powertrain"; }
    }

    part def '変速機制御ユニット' {
        doc /* AMT の変速機制御ユニット（TCU）。変速とクラッチを制御する。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute '変速時間' : DurationValue default 0.6 [s];
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.5 [kg] + '基板'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力';
        port 'CAN' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.2; }
        @Safety { asil = Asil::B; isolationGroup = "powertrain"; }
    }

    part def '自動変速機AMT' {
        doc /* 12 速 AMT（機械式自動変速機）：TCU、空圧クラッチ、シフトアクチュエータ、メインギヤボックス、レンジ切替。 */
        @Placement { mode = LayoutMode::fixed; }
        @Material { name = "aluminium gearbox, painted"; finish = Finish::paint; color = "#3b4046"; roughness = 0.55; }
        attribute '段数' : Integer default 12;
        attribute '最低速段比' : Real default 14.7;
        attribute 'ハウジング質量' : MassValue default 45 [kg];
        part 'TCU' : '変速機制御ユニット' { @Placement { xM = -0.375; yM = 0.0; zM = 0.26; } }
        part 'クラッチ' : 'クラッチアクチュエータ' { @Placement { xM = 0.425; yM = 0.0; zM = 0.0; } }
        part 'シフトアクチュエータ' : 'シフトアクチュエータ型' { @Placement { xM = 0.05; yM = 0.0; zM = 0.22; } }
        part '主変速機' : '主変速機型' { @Placement { xM = 0.05; yM = 0.0; zM = -0.08; } }
        part 'レンジ切替機構' : 'レンジ切替機構型' { @Placement { xM = -0.375; yM = 0.0; zM = 0.0; } }
        part '出力軸センサ' : '速度センサ' { @Placement { xM = -0.48; yM = 0.0; zM = -0.27; } }
        port '入力' : ~'トルクポート';
        port '出力' : 'トルクポート';
        attribute mass :> ISQ::mass = 'ハウジング質量' + 'TCU'.mass + 'クラッチ'.mass + 'シフトアクチュエータ'.mass + '主変速機'.mass + 'レンジ切替機構'.mass + '出力軸センサ'.mass;
        attribute '消費電力' : PowerValue = 'TCU'.'消費電力' + 'クラッチ'.'消費電力' + 'シフトアクチュエータ'.'消費電力' + '出力軸センサ'.'消費電力';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 1.0 [m]; :>> width = 0.6 [m]; :>> height = 0.62 [m]; }
        item gearbox : Rod {
            doc /* クラッチハウジングと変速機本体。 */
            :>> radius = 0.28 [m];
            :>> length = 1.0 [m];
        }
        @Safety { asil = Asil::B; isolationGroup = "powertrain"; }
    }

    part def '排出ガス後処理装置' {
        doc /* 排気後処理：DOC、DPF（差圧センサ付き）、尿素 SCR、尿素噴射弁、NOx センサ 2 個。ポスト新長期規制相当。 */
        @Placement { mode = LayoutMode::fixed; }
        @Material { name = "stainless canister"; finish = Finish::brushedSteel; color = "#b9bec4"; roughness = 0.3; }
        attribute 'NOx浄化率' : Real default 0.97;
        attribute 'キャニスタ質量' : MassValue default 25 [kg];
        part '酸化触媒' : '酸化触媒型' { @Placement { xM = 0.355; yM = -0.05; zM = 0.0; } }
        part 'DPF' : 'DPF型' { @Placement { xM = 0.06; yM = -0.05; zM = 0.0; } }
        part 'SCR触媒' : 'SCR触媒型' { @Placement { xM = -0.295; yM = -0.05; zM = 0.0; } }
        part '尿素水噴射装置' : '尿素水噴射装置型' { @Placement { xM = -0.12; yM = 0.17; zM = 0.1; } }
        part '上流NOxセンサ' : 'NOxセンサ' { @Placement { xM = 0.1; yM = 0.17; zM = 0.1; } }
        part '下流NOxセンサ' : 'NOxセンサ' { @Placement { xM = -0.4; yM = 0.17; zM = 0.1; } }
        part 'DPF差圧センサ' : '差圧センサ' { @Placement { xM = 0.06; yM = 0.17; zM = -0.1; } }
        port '排気入口' : ~'排気ポート';
        attribute mass :> ISQ::mass = 'キャニスタ質量' + '酸化触媒'.mass + 'DPF'.mass + 'SCR触媒'.mass + '尿素水噴射装置'.mass + '上流NOxセンサ'.mass + '下流NOxセンサ'.mass + 'DPF差圧センサ'.mass;
        attribute '消費電力' : PowerValue = '尿素水噴射装置'.'消費電力' + '上流NOxセンサ'.'消費電力' + '下流NOxセンサ'.'消費電力' + 'DPF差圧センサ'.'消費電力';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 1.0 [m]; :>> width = 0.5 [m]; :>> height = 0.5 [m]; }
        item 'キャニスタ' : Block {
            doc /* 右サイドレール外側の後処理ボックス。 */
            :>> length = 1.0 [m];
            :>> width = 0.5 [m];
            :>> height = 0.5 [m];
        }
    }

    part def '尿素水供給装置' {
        doc /* 尿素水（AdBlue）供給：タンク 40 L とポンプ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'タンク部' : '尿素水タンク';
        part 'ポンプ' : '尿素水ポンプ';
        attribute '充填質量' : MassValue default 44 [kg];
        attribute mass :> ISQ::mass = '充填質量' + 'タンク部'.mass + 'ポンプ'.mass;
        attribute '消費電力' : PowerValue = 'タンク部'.'消費電力' + 'ポンプ'.'消費電力';
    }

    part def 'プロペラシャフト系' {
        doc /* プロペラシャフト系：シャフト 2 本、自在継手 2 個、中間軸受。 */
        @Placement { mode = LayoutMode::fixed; }
        @Material { name = "steel tube shaft"; finish = Finish::metal; color = "#5a5f66"; }
        part '前側シャフト' : 'プロペラシャフト型' { @Placement { xM = 0.8875; yM = 0.0; zM = 0.0; } }
        part '後側シャフト' : 'プロペラシャフト型' { @Placement { xM = -0.8875; yM = 0.0; zM = 0.0; } }
        part '前側自在継手' : '自在継手' { @Placement { xM = 1.8; yM = 0.0; zM = 0.0; } }
        part '後側自在継手' : '自在継手' { @Placement { xM = -1.8; yM = 0.0; zM = 0.0; } }
        part 'センターベアリング' : 'センターベアリング型' { @Placement { xM = 0.0; yM = 0.0; zM = 0.0; } }
        port '入力' : ~'トルクポート';
        port '出力' : 'トルクポート';
        attribute mass :> ISQ::mass = '前側シャフト'.mass + '後側シャフト'.mass + '前側自在継手'.mass + '後側自在継手'.mass + 'センターベアリング'.mass;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 3.8 [m]; :>> width = 0.2 [m]; :>> height = 0.2 [m]; }
    }

    part def 'ディーゼルパワートレイン' {
        doc /*
         * パワートレイン：9.8 L ディーゼル、12 速 AMT、プロペラシャフト、排気後処理、尿素水供給、燃料系。
         * 効率は燃料タンクから車輪までの総合効率。
         */
        @Placement { mode = LayoutMode::fixed; }
        attribute '定格出力' : PowerValue default 280 [kW];
        attribute efficiency : Real default 0.36;
        part 'エンジン' : 'ディーゼルエンジン' { @Placement { xM = 2.5; yM = -0.02; zM = 0.1025; } }
        part '変速機' : '自動変速機AMT' { @Placement { xM = 1.15; yM = -0.02; zM = 0.0025; } }
        part 'プロペラシャフト' : 'プロペラシャフト系' { @Placement { xM = -1.25; yM = -0.02; zM = -0.2875; } }
        part '後処理' : '排出ガス後処理装置' { @Placement { xM = -0.05; yM = -0.82; zM = -0.3475; } }
        part '尿素水装置' : '尿素水供給装置' { @Placement { xM = -0.95; yM = -0.87; zM = -0.3475; } }
        part '燃料装置' : '燃料装置型' { @Placement { xM = -0.1; yM = 0.82; zM = -0.3275; } }
        interface 'クラッチ駆動' : 'ドライブライン' connect '主側' ::> 'エンジン'.'クランク出力' to '被駆動側' ::> '変速機'.'入力';
        interface '変速機からプロペラシャフトへ' : 'ドライブライン' connect '主側' ::> '変速機'.'出力' to '被駆動側' ::> 'プロペラシャフト'.'入力';
        interface '排気管' : '排気管路' connect 'エンジン' ::> 'エンジン'.'排気出口' to '後処理' ::> '後処理'.'排気入口';
        interface '燃料供給' : '燃料配管' connect 'タンク部' ::> '燃料装置'.'燃料出口' to '給電' ::> 'エンジン'.'燃料噴射装置'.'燃料入口';
        attribute mass :> ISQ::mass = 'エンジン'.mass + '変速機'.mass + 'プロペラシャフト'.mass + '後処理'.mass + '尿素水装置'.mass + '燃料装置'.mass;
        attribute '消費電力' : PowerValue = 'エンジン'.'消費電力' + '変速機'.'消費電力' + '後処理'.'消費電力' + '尿素水装置'.'消費電力' + '燃料装置'.'消費電力';
        @Safety { asil = Asil::C; isolationGroup = "powertrain"; }
    }

    part def '燃料装置型' {
        doc /*
         * 燃料系：左サイドレール外側のアルミ製角形燃料タンク 400 L、フィードポンプ、フィルタ、残量センサ。
         * 搭載エネルギーは容量と軽油の体積エネルギー（約 9900 kWh/m3）から求める。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium tank"; finish = Finish::metal; color = "#c3c8cd"; roughness = 0.25; }
        attribute 'タンク容量' : VolumeValue default 0.4 [m^3];
        attribute '使用可能比率' : Real default 0.9;
        attribute '体積あたりエネルギーkWhm3' : Real default 9900.0;
        attribute '積荷密度kgm3' : Real default 830.0;
        attribute 'タンク乾燥質量' : MassValue default 48 [kg];
        part 'フィードポンプ' : 'フィードポンプ型';
        part '燃料フィルタ' : '燃料フィルタ型';
        part '残量センサ' : '燃料残量センサ';
        attribute '蓄積エネルギー' : EnergyValue = 'タンク容量' / (1 [m^3]) * '体積あたりエネルギーkWhm3' * (1 [kW * h]);
        attribute '使用可能エネルギー' : EnergyValue = '蓄積エネルギー' * '使用可能比率';
        attribute mass :> ISQ::mass = 'タンク容量' / (1 [m^3]) * '積荷密度kgm3' * (1 [kg]) + 'タンク乾燥質量' + 'フィードポンプ'.mass + '燃料フィルタ'.mass + '残量センサ'.mass;
        attribute '消費電力' : PowerValue = 'フィードポンプ'.'消費電力' + '残量センサ'.'消費電力';
        port '燃料出口' : '燃料ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 1.3 [m]; :>> width = 0.55 [m]; :>> height = 0.6 [m]; }
        item 'タンク部' : Block {
            doc /* 角形アルミタンク。 */
            :>> length = 1.3 [m];
            :>> width = 0.55 [m];
            :>> height = 0.6 [m];
        }
    }

    /* ------------------------------------------------------------ */
    /* ドライブバイワイヤ（操舵、制動、駆動力） */
    /* ------------------------------------------------------------ */

    abstract part def 'バイワイヤアクチュエータ' {
        doc /* 主系と冗長系の 2 系統の CAN FD で指令され、24 V ネット A と B の 2 系統で給電されるアクチュエータ。 */
        @Material { name = "cast aluminium housing"; finish = Finish::metal; color = "#9aa0a7"; roughness = 0.5; }
        attribute mass :> ISQ::mass;
        attribute latency : DurationValue;
        attribute '消費電力' : PowerValue;
        attribute '指令系統数' : Integer default 2;
        attribute '供給系統数' : Integer default 2;
        port '24V電源' : ~'24V電源ポート';
        port 'B系24V電源' : ~'24V電源ポート';
    }

    /* ---- 冗長化した電動パワーステアリング（EPS） ---- */

    part def '操舵制御ユニット' {
        doc /* 操舵制御 ECU（1 チャネル分）。ECU 基板と、同じ系統のインバータへのゲート指令を持つ。2 台で冗長。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute 'ループ周期' : DurationValue default 0.002 [s];
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.35 [kg] + '基板'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力';
        port 'CAN' : 'CANポート' { :>> '周期' = 0.01 [s]; }
        port 'ゲート' : 'ゲート指令ポート';
        port 'トルク入力' : ~'センサ信号ポート';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; failOperational = true; }
    }

    part def 'モータ巻線' {
        doc /* 二重巻線モータの三相巻線 1 組。専用のインバータで駆動する。 */
        attribute '定格電流' : ElectricCurrentValue default 60 [A];
        attribute 'トルク配分' : Real default 0.5;
        attribute mass :> ISQ::mass default 2.5 [kg];
        port '相出力' : ~'相電力ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.08 [m]; :>> height = 0.04 [m]; }
    }

    part def '二重巻線EPSモータ' {
        doc /*
         * 二重巻線 EPS モータ。巻線 A と B は独立したインバータと電源（ネット A、B）で動き、
         * 片側が故障しても 50 % のアシストトルクを保つ（フェールオペレーショナル）。
         */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '最大トルク瞬時Nm' : Real default 60.0;
        attribute '巻線数' : Integer default 2;
        attribute '片系巻線トルク比' : Real = 'A系巻線'.'トルク配分';
        part 'A系巻線' : 'モータ巻線';
        part 'B系巻線' : 'モータ巻線';
        part 'ロータ' : 'モータロータ';
        part 'A系レゾルバ' : 'レゾルバ';
        part 'B系レゾルバ' : 'レゾルバ';
        attribute mass :> ISQ::mass = 1.5 [kg] + 'A系巻線'.mass + 'B系巻線'.mass + 'ロータ'.mass + 'A系レゾルバ'.mass + 'B系レゾルバ'.mass;
        attribute '消費電力' : PowerValue = 'A系レゾルバ'.'消費電力' + 'B系レゾルバ'.'消費電力';
        port 'シャフト' : '操舵トルクポート';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; failOperational = true; }
    }

    part def 'トルク舵角センサ' {
        doc /* 入力軸の冗長トルク角センサ（独立したホール素子 2 個）。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '角度分解能deg' : Real default 0.1;
        part 'ホール素子群' : 'ホール素子'[2];
        attribute mass :> ISQ::mass = 0.4 [kg] + 2 * 'ホール素子群'.mass;
        attribute '消費電力' : PowerValue = 2 * 'ホール素子群'.'消費電力';
        port '信号' : 'センサ信号ポート';
    }

    part def 'ボールナット式ステアリングギヤ' {
        doc /* ボールナット式ステアリングギア。入力軸に EPS モータが付く。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '減速比' : Real default 22.0;
        part 'ボールナット' : 'ボールナット型';
        part 'セクタシャフト' : 'セクタシャフト型';
        part 'ピットマンアーム' : 'ピットマンアーム型';
        port '入力' : ~'操舵トルクポート';
        port '出力' : '操舵トルクポート';
        attribute mass :> ISQ::mass = 18 [kg] + 'ボールナット'.mass + 'セクタシャフト'.mass + 'ピットマンアーム'.mass;
    }

    part def 'ステアリングリンケージ' {
        doc /* ピットマンアームから第 1 軸のナックルへのドラッグリンクとタイロッド、第 2 軸へのリレーロッドとタイロッド。 */
        @Placement { mode = LayoutMode::fixed; }
        part 'ドラッグリンク' : 'ドラッグリンク型' { @Placement { xM = 0.8125; yM = -0.62; zM = 0.05; } }
        part 'タイロッド' : 'タイロッド型' { @Placement { xM = 0.5625; yM = 0.0; zM = -0.05; } }
        part 'リレーロッド' : 'ドラッグリンク型' { doc /* 第 1 軸から第 2 軸へ操舵を伝えるリレーロッド。 */ @Placement { xM = -0.3375; yM = -0.62; zM = 0.05; } }
        part '第2軸タイロッド' : 'タイロッド型' { @Placement { xM = -1.2375; yM = 0.0; zM = -0.05; } }
        port '入力' : ~'操舵トルクポート';
        attribute mass :> ISQ::mass = 'ドラッグリンク'.mass + 'タイロッド'.mass + 'リレーロッド'.mass + '第2軸タイロッド'.mass;
    }

    part def '冗長電動ステアリング' :> 'バイワイヤアクチュエータ' {
        doc /*
         * 冗長化した電動パワーステアリング（コラムとボールナット式ギアは機械的につながり、EPS がアシストと自動操舵を行う）。二重巻線モータ、巻線ごとのインバータ 2 台と
         * 操舵 ECU 2 台、冗長トルク角センサ、ボールナット式ギア、リンク機構。右ハンドルでギアは右サイドレールに付く。
         * 片系が故障しても残りの系で 50 % のアシストを続ける。
         */
        @Placement { mode = LayoutMode::fixed; }
        attribute :>> mass = 'A系操舵ECU'.mass + 'B系操舵ECU'.mass + 'A系インバータ'.mass + 'B系インバータ'.mass + 'モータ'.mass + 'トルクセンサ'.mass + 'ステアリングギヤ'.mass + 'リンケージ'.mass;
        attribute :>> latency = 0.03 [s];
        attribute :>> '消費電力' = 600 [W];
        attribute 'インバータ数' : Integer default 2;
        attribute '故障警報信号' : Boolean default true {
            doc /* 操舵系の故障を警告する（UN R79 5.4）。 */
        }
        attribute '電子機器電力' : PowerValue = 'A系操舵ECU'.'消費電力' + 'B系操舵ECU'.'消費電力' + 'A系インバータ'.'消費電力' + 'B系インバータ'.'消費電力' + 'モータ'.'消費電力' + 'トルクセンサ'.'消費電力';
        part 'A系操舵ECU' : '操舵制御ユニット' { @Placement { xM = 1.1963; yM = -0.62; zM = 0.3535; } }
        part 'B系操舵ECU' : '操舵制御ユニット' { @Placement { xM = 1.1963; yM = -0.62; zM = 0.2035; } }
        part 'A系インバータ' : 'モータインバータ' { @Placement { xM = 0.9963; yM = -0.62; zM = 0.3535; } }
        part 'B系インバータ' : 'モータインバータ' { @Placement { xM = 0.9963; yM = -0.62; zM = 0.2035; } }
        part 'モータ' : '二重巻線EPSモータ' { @Placement { xM = 1.0663; yM = -0.58; zM = 0.0335; } }
        part 'トルクセンサ' : 'トルク舵角センサ' { @Placement { xM = 1.2663; yM = -0.55; zM = 0.1335; } }
        part 'ステアリングギヤ' : 'ボールナット式ステアリングギヤ' { @Placement { xM = 1.1163; yM = -0.55; zM = -0.1265; } }
        part 'リンケージ' : 'ステアリングリンケージ' { @Placement { xM = -0.0062; yM = 0.0; zM = -0.2965; } }
        interface '操舵アシスト' : '操舵駆動' connect 'モータ' ::> 'モータ'.'シャフト' to 'ステアリングギヤ' ::> 'ステアリングギヤ'.'入力';
        interface 'ギヤからリンケージへ' : '操舵駆動' connect 'モータ' ::> 'ステアリングギヤ'.'出力' to 'ステアリングギヤ' ::> 'リンケージ'.'入力';
        interface 'A系相電流' : 'モータ相リンク' connect 'インバータ' ::> 'A系インバータ'.'相出力' to '巻線' ::> 'モータ'.'A系巻線'.'相出力';
        interface 'B系相電流' : 'モータ相リンク' connect 'インバータ' ::> 'B系インバータ'.'相出力' to '巻線' ::> 'モータ'.'B系巻線'.'相出力';
        interface 'A系ゲート信号' : 'ゲート指令リンク' connect '制御器' ::> 'A系操舵ECU'.'ゲート' to 'インバータ' ::> 'A系インバータ'.'ゲート';
        interface 'B系ゲート信号' : 'ゲート指令リンク' connect '制御器' ::> 'B系操舵ECU'.'ゲート' to 'インバータ' ::> 'B系インバータ'.'ゲート';
        interface 'A系トルク' : 'センサ信号リンク' connect 'センサ部' ::> 'トルクセンサ'.'信号' to '受信側' ::> 'A系操舵ECU'.'トルク入力';
        interface 'B系トルク' : 'センサ信号リンク' connect 'センサ部' ::> 'トルクセンサ'.'信号' to '受信側' ::> 'B系操舵ECU'.'トルク入力';
        port :>> '24V電源' { in :>> current = 25 [A]; }
        port :>> 'B系24V電源' { in :>> current = 25 [A]; }
        @Budget { powerW = 300.0; latencyMs = 30.0; bus = "lv24a"; }
        @Safety { asil = Asil::D; isolationGroup = "chassis"; failOperational = true; barrier = true; }
    }

    /* ---- ブレーキバイワイヤ（EBS） ---- */

    part def 'EBS制御ユニット' {
        doc /*
         * 電子制御ブレーキ（EBS）ECU。型式 BBW-24。ロックステップ MCU で 10 ms 周期の制御タスクを実行し、
         * 主系と冗長系の XBR 減速指令を 2 系統の CAN FD で受ける。ABS とブレーキ配分もここで行う。
         * 組込みソフトはリバースモデリングで BrakeEcuReverse パッケージに起こした（BbwEcuSoftware を割り当て）。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute 'タスク周期' : DurationValue default 0.01 [s];
        attribute 'ウォッチドッグタイムアウト' : DurationValue default 0.03 [s];
        attribute 'ABS制御周期' : DurationValue default 0.005 [s];
        attribute 'CPUクロックMHz' : Real default 300.0;
        attribute 'フラッシュKiB' : Real default 4096.0;
        attribute '故障警報信号' : Boolean default true {
            doc /* 電気制御系統の故障をメータの黄色、赤色警告灯で運転者（無人時は遠隔監視）へ知らせる（UN R13 5.2.1.29）。 */
        }
        part '基板' : 'ECU基板';
        part 'バルブドライバ群' : 'ゲートドライバ型'[4];
        attribute mass :> ISQ::mass = 0.6 [kg] + '基板'.mass + 4 * 'バルブドライバ群'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 4 * 'バルブドライバ群'.'消費電力';
        port '主系CAN端子' : 'CANポート' { :>> '周期' = 0.01 [s]; }
        port '副系CAN端子' : 'CANポート' { :>> '周期' = 0.01 [s]; }
        port 'リターダCAN端子' : 'CANポート' { :>> '負荷率' = 0.05; }
        port '前輪系駆動' : '弁駆動ポート';
        port '後輪系駆動' : '弁駆動ポート';
        port '駐車ブレーキ駆動' : '弁駆動ポート';
        port 'ABS駆動' : '弁駆動ポート';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; failOperational = true; }
    }

    part def '車軸モジュレータ' {
        doc /*
         * 電空式アクスルモジュレータ。ECU の圧力指令をブレーキチャンバ圧に変える。
         * responseTime は指令から圧力立ち上がりまで。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "cast aluminium valve body"; finish = Finish::metal; color = "#8e949b"; roughness = 0.5; }
        attribute 'チャネル数' : Integer default 1;
        attribute '最大吐出圧' : PressureValue default 850000 [Pa];
        attribute 'ハウジング質量' : MassValue default 2.5 [kg];
        part 'A系' : 'モジュレータ系統';
        part 'ドライバ基板' : 'ECU基板';
        attribute '応答時間' : DurationValue = 'A系'.'応答時間';
        attribute mass :> ISQ::mass default 'ハウジング質量' + 'A系'.mass + 'ドライバ基板'.mass;
        attribute '消費電力' : PowerValue default 'A系'.'消費電力' + 'ドライバ基板'.'消費電力';
        port '供給' : ~'空気ポート';
        port '送出' : '空気ポート';
        port '駆動' : ~'弁駆動ポート';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; }
    }

    part def '後軸モジュレータ型' :> '車軸モジュレータ' {
        doc /* 後 2 軸用の 2 チャネルモジュレータ。左右独立に圧力を制御する。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute :>> 'チャネル数' = 2;
        part 'B系' : 'モジュレータ系統';
        attribute :>> mass = 'ハウジング質量' + 'A系'.mass + 'B系'.mass + 'ドライバ基板'.mass;
        attribute :>> '消費電力' = 'A系'.'消費電力' + 'B系'.'消費電力' + 'ドライバ基板'.'消費電力';
        port '右送出口' : '空気ポート';
    }

    part def 'ABS圧力制御弁' {
        doc /* 前輪 ABS 圧力制御弁（1 輪分）：保持弁と減圧弁。EBS ECU が 5 ms 周期で制御する。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '保持弁' : '電磁弁';
        part '解放弁' : '電磁弁';
        attribute mass :> ISQ::mass = 0.5 [kg] + '保持弁'.mass + '解放弁'.mass;
        attribute '消費電力' : PowerValue = '保持弁'.'消費電力' + '解放弁'.'消費電力';
        port '供給' : ~'空気ポート';
        port '送出' : '空気ポート';
        port '駆動' : ~'弁駆動ポート';
    }

    part def '駐車ブレーキモジュール' {
        doc /* 電空式パーキングブレーキ：スプリングブレーキチャンバを排気してばねで制動する（ホイールパーク）。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '作動時間' : DurationValue default 0.5 [s];
        part '加圧弁' : '電磁弁';
        part '解放弁' : '電磁弁';
        part 'リレー' : 'リレーピストン';
        part '圧力センサ' : 'ブレーキ圧センサ';
        attribute mass :> ISQ::mass = 0.8 [kg] + '加圧弁'.mass + '解放弁'.mass + 'リレー'.mass + '圧力センサ'.mass;
        attribute '消費電力' : PowerValue = '加圧弁'.'消費電力' + '解放弁'.'消費電力' + '圧力センサ'.'消費電力';
        port '供給' : ~'空気ポート';
        port '送出' : '空気ポート';
        port '駆動' : ~'弁駆動ポート';
        @Safety { asil = Asil::C; isolationGroup = "chassis"; }
    }

    part def 'リターダ制御器' {
        doc /* リターダ制御 ECU。EBS からの減速配分指令で磁石位相を切り替える。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.4 [kg] + '基板'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力';
        port 'CAN' : 'CANポート' { :>> '負荷率' = 0.05; }
    }

    part def '永久磁石式リターダ' {
        doc /*
         * 永久磁石式リターダ（補助ブレーキ）。プロペラシャフト上で渦電流による制動力を出し、
         * 長い下り坂でフットブレーキのフェードを防ぐ。日本の大型車で一般的な装備。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "finned steel rotor"; finish = Finish::metal; color = "#55595f"; }
        attribute '制動トルクNm' : Real default 1800.0;
        part 'ロータ' : 'リターダロータ';
        part '磁石' : 'リターダ磁石列';
        part 'アクチュエータ' : 'リターダ切替アクチュエータ';
        part '制御器' : 'リターダ制御器';
        attribute mass :> ISQ::mass = 'ロータ'.mass + '磁石'.mass + 'アクチュエータ'.mass + '制御器'.mass;
        attribute '消費電力' : PowerValue = 'アクチュエータ'.'消費電力' + '制御器'.'消費電力';
    }

    part def 'エアタンク' {
        doc /* ブレーキ回路ごとの鋼製エアタンク。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "painted steel tank"; finish = Finish::paint; color = "#2a2d31"; }
        attribute 'タンク容量' : VolumeValue default 0.04 [m^3];
        part 'ドレン' : 'ドレンバルブ';
        attribute mass :> ISQ::mass = 14 [kg] + 'ドレン'.mass;
        port '出口' : '空気ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.7 [m]; :>> width = 0.26 [m]; :>> height = 0.26 [m]; }
        item shell : Rod { :>> radius = 0.13 [m]; :>> length = 0.7 [m]; }
    }

    part def 'エアドライヤ型' {
        doc /* エアドライヤ：乾燥剤カートリッジ、パージヒータ、電子ガバナ。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'カートリッジ' : 'ドライヤカートリッジ';
        part 'ヒータ' : 'ドライヤヒータ';
        part 'ガバナ' : 'ガバナ型';
        attribute mass :> ISQ::mass = 3 [kg] + 'カートリッジ'.mass + 'ヒータ'.mass + 'ガバナ'.mass;
        attribute '消費電力' : PowerValue = 'ヒータ'.'消費電力' + 'ガバナ'.'消費電力';
    }

    part def 'エア処理ユニット' {
        doc /* 空気供給系：コンプレッサ、エアドライヤ、4 回路保護弁、前軸、後軸、駐車、エアサス用のエアタンク。 */
        @Placement { mode = LayoutMode::fixed; }
        attribute 'カットアウト圧力' : PressureValue default 980000 [Pa];
        part 'コンプレッサ' : 'エアコンプレッサ' { @Placement { xM = 4.525; yM = 0.55; zM = 0.0825; } }
        part 'エアドライヤ' : 'エアドライヤ型' { @Placement { xM = 3.675; yM = -0.62; zM = 0.0225; } }
        part '保護弁' : '保護弁型' { @Placement { xM = 3.955; yM = -0.62; zM = 0.0825; } }
        part '前輪系エアタンク' : 'エアタンク' { @Placement { xM = 0.325; yM = 0.62; zM = -0.0775; } }
        part '後輪系エアタンク' : 'エアタンク' { @Placement { xM = 0.325; yM = -0.62; zM = -0.0775; } }
        part '駐車ブレーキ系エアタンク' : 'エアタンク' { @Placement { xM = -0.525; yM = 0.62; zM = -0.0775; } }
        part 'サスペンション用エアタンク' : 'エアタンク' { @Placement { xM = -4.325; yM = 0.62; zM = -0.0775; } }
        attribute mass :> ISQ::mass = 'コンプレッサ'.mass + 'エアドライヤ'.mass + '保護弁'.mass + '前輪系エアタンク'.mass + '後輪系エアタンク'.mass + '駐車ブレーキ系エアタンク'.mass + 'サスペンション用エアタンク'.mass;
        attribute '消費電力' : PowerValue = 'エアドライヤ'.'消費電力';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; }
    }

    part def 'ブレーキバイワイヤ' :> 'バイワイヤアクチュエータ' {
        doc /*
         * ブレーキバイワイヤ（フルエア式 EBS）。EBS ECU、前軸モジュレータと前輪 ABS 弁 2 個、
         * 後 2 軸用 2 チャネルモジュレータ、パーキングブレーキ、永久磁石式リターダ、空気供給系。
         * 2 系統の指令と 2 系統の電源でフェールオペレーショナルに作動する。
         * latency は ECU の制御周期と後軸モジュレータの応答時間の和。
         */
        @Placement { mode = LayoutMode::fixed; }
        attribute :>> mass = 'EBS_ECU'.mass + '前軸モジュレータ'.mass + '後軸モジュレータ'.mass + '前左ABS弁'.mass + '前右ABS弁'.mass + '駐車ブレーキ'.mass + 'リターダ'.mass + '空気供給'.mass;
        attribute :>> latency = 'EBS_ECU'.'タスク周期' + '後軸モジュレータ'.'応答時間';
        attribute '後軸チャンバ充填時間' : DurationValue default 0.33 [s] {
            doc /* 後後軸のスプリングブレーキチャンバ（最も遠く条件の悪いチャンバ）が漸近圧の 75 % に達するまでの充気時間（配管 6 m、EBS 実測相当）。 */
        }
        attribute '75パーセント応答時間' : DurationValue = 'EBS_ECU'.'タスク周期' + '後軸モジュレータ'.'応答時間' + '後軸チャンバ充填時間';
        attribute :>> '消費電力' = 180 [W];
        attribute '電子機器電力' : PowerValue = 'EBS_ECU'.'消費電力' + '前軸モジュレータ'.'消費電力' + '後軸モジュレータ'.'消費電力' + '前左ABS弁'.'消費電力' + '前右ABS弁'.'消費電力' + '駐車ブレーキ'.'消費電力' + 'リターダ'.'消費電力' + '空気供給'.'消費電力';
        part 'EBS_ECU' : 'EBS制御ユニット' { @Placement { xM = 0.675; yM = 0.5; zM = 0.1975; } }
        part '前軸モジュレータ' : '車軸モジュレータ' { @Placement { xM = 3.775; yM = 0.52; zM = 0.2075; } }
        part '後軸モジュレータ' : '後軸モジュレータ型' { @Placement { xM = -2.585; yM = 0.5; zM = 0.2475; } }
        part '前左ABS弁' : 'ABS圧力制御弁' { @Placement { xM = 4.315; yM = 0.55; zM = 0.0475; } }
        part '前右ABS弁' : 'ABS圧力制御弁' { @Placement { xM = 4.315; yM = -0.55; zM = 0.0475; } }
        part '駐車ブレーキ' : '駐車ブレーキモジュール' { @Placement { xM = -0.525; yM = -0.5; zM = 0.1975; } }
        part 'リターダ' : '永久磁石式リターダ' { @Placement { xM = 1.825; yM = 0.0; zM = -0.0325; } }
        part '空気供給' : 'エア処理ユニット' { @Placement { xM = 0.0; yM = 0.0; zM = 0.045; } @Routed { medium = "fluid"; } }
        interface '前輪系回路' : 'エア配管' connect '供給' ::> '空気供給'.'前輪系エアタンク'.'出口' to '送出' ::> '前軸モジュレータ'.'供給';
        interface '後輪系回路' : 'エア配管' connect '供給' ::> '空気供給'.'後輪系エアタンク'.'出口' to '送出' ::> '後軸モジュレータ'.'供給';
        interface '駐車ブレーキ回路' : 'エア配管' connect '供給' ::> '空気供給'.'駐車ブレーキ系エアタンク'.'出口' to '送出' ::> '駐車ブレーキ'.'供給';
        interface '前左ABS弁給気' : 'エア配管' connect '供給' ::> '前軸モジュレータ'.'送出' to '送出' ::> '前左ABS弁'.'供給';
        interface '前右ABS弁給気' : 'エア配管' connect '供給' ::> '前軸モジュレータ'.'送出' to '送出' ::> '前右ABS弁'.'供給';
        interface '前輪系弁駆動' : '弁駆動' connect '運転者' ::> 'EBS_ECU'.'前輪系駆動' to '弁' ::> '前軸モジュレータ'.'駆動';
        interface '後輪系弁駆動' : '弁駆動' connect '運転者' ::> 'EBS_ECU'.'後輪系駆動' to '弁' ::> '後軸モジュレータ'.'駆動';
        interface '駐車ブレーキ弁駆動' : '弁駆動' connect '運転者' ::> 'EBS_ECU'.'駐車ブレーキ駆動' to '弁' ::> '駐車ブレーキ'.'駆動';
        interface '左ABS弁配管' : '弁駆動' connect '運転者' ::> 'EBS_ECU'.'ABS駆動' to '弁' ::> '前左ABS弁'.'駆動';
        interface '右ABS弁配管' : '弁駆動' connect '運転者' ::> 'EBS_ECU'.'ABS駆動' to '弁' ::> '前右ABS弁'.'駆動';
        interface 'リターダ指令' : 'CANリンク' connect '端A' ::> 'EBS_ECU'.'リターダCAN端子' to '端B' ::> 'リターダ'.'制御器'.'CAN';
        port :>> '24V電源' { in :>> current = 7.5 [A]; }
        port :>> 'B系24V電源' { in :>> current = 7.5 [A]; }
        @Budget { powerW = 90.0; latencyMs = 35.0; bus = "lv24a"; }
        @Safety { asil = Asil::D; isolationGroup = "chassis"; failOperational = true; barrier = true; }
    }

    /* ---- 駆動力指令 ---- */

    part def 'トルクリクエスト系統' {
        doc /* トルク指令経路 1 本：XBR と TSC1 の調停をして J1939 の TSC1 をエンジン ECM へ送る。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute 'リクエスト周期' : DurationValue default 0.01 [s];
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.1 [kg] + '基板'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力';
    }

    part def 'スロットルバイワイヤ' :> 'バイワイヤアクチュエータ' {
        doc /*
         * 駆動力指令ゲートウェイ。主系と冗長系の 2 チャネルでトルク指令をエンジン ECM へ送る。
         * 冗長系はトルクをゼロへ絞る指令しか出せない。
         */
        @Placement { mode = LayoutMode::connectivity; }
        attribute :>> mass = 0.6 [kg] + '主系統'.mass + 'フォールバック系統'.mass;
        attribute :>> latency = 0.02 [s];
        attribute :>> '消費電力' = 8 [W];
        part '主系統' : 'トルクリクエスト系統';
        part 'フォールバック系統' : 'トルクリクエスト系統' { doc /* トルク制限専用。冗長系はトルクを下げることしかできない。 */ }
        port :>> '24V電源' { in :>> current = 0.3 [A]; }
        port :>> 'B系24V電源' { in :>> current = 0.3 [A]; }
        port 'シャシCAN端子' : 'CANポート' { :>> '負荷率' = 0.1; }
        port 'パワートレインCAN端子' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.1; }
        @Budget { powerW = 8.0; latencyMs = 20.0; bus = "lv24a"; }
        @Safety { asil = Asil::C; isolationGroup = "powertrain"; barrier = true; }
    }

    part def 'ドライブバイワイヤ型' {
        doc /*
         * ドライブバイワイヤ：操舵（冗長化 EPS）、制動（EBS）、駆動力の各アクチュエータ。いずれも 2 系統指令、2 系統給電。
         * 部品はフレームと前軸まわりに分散して取り付ける。
         */
        @Placement { mode = LayoutMode::fixed; }
        attribute 'ゲートウェイ遅れ' : DurationValue default 0.002 [s];
        part '操舵装置' : '冗長電動ステアリング' { @Placement { xM = 3.8325; yM = 0.0; zM = 0.06; } @Routed { medium = "signal"; } }
        part 'ブレーキ' : 'ブレーキバイワイヤ' { @Placement { xM = -0.4262; yM = 0.0; zM = -0.134; } @Routed { medium = "fluid"; } }
        part 'スロットル' : 'スロットルバイワイヤ' { @Placement { xM = 2.9988; yM = 0.52; zM = 0.1635; } }
        attribute 'ブレーキ遅れ' : DurationValue = 'ゲートウェイ遅れ' + 'ブレーキ'.latency;
        attribute '消費電力' : PowerValue = '操舵装置'.'消費電力' + 'ブレーキ'.'消費電力' + 'スロットル'.'消費電力';
        attribute mass :> ISQ::mass = '操舵装置'.mass + 'ブレーキ'.mass + 'スロットル'.mass;
    }

    /* ------------------------------------------------------------ */
    /* 認識センサ */
    /* ------------------------------------------------------------ */

    abstract part def 'センサ' {
        doc /* 認識センサの共通定義：Ethernet でゾーンスイッチへ、24 V ネット A から給電、gPTP で時刻同期。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute mass :> ISQ::mass;
        attribute '消費電力' : PowerValue;
        attribute latency : DurationValue default 0.05 [s];
        attribute '検知距離' : LengthValue default 100 [m];
        attribute 'フレームレートHz' : Real default 10.0;
        attribute 'ハウジング質量' : MassValue default 0.3 [kg];
        port 'Ethernet端子' : 'Ethernetポート';
        port '24V電源' : ~'24V電源ポート';
        port 'PTP' : ~'時刻同期ポート';
        part '取付部' : 'センサ取付台';
    }

    part def 'LiDARレーザ送信部' {
        doc /* 1550 nm ファイバレーザ送光部（目に安全なクラス 1）。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '波長' : LengthValue default 0.00000155 [m];
        part source : 'ファイバーレーザ光源';
        part '運転者' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 0.05 [kg] + source.mass + '運転者'.mass;
        attribute '消費電力' : PowerValue = source.'消費電力' + '運転者'.'消費電力';
    }

    part def 'LiDARスキャナ' {
        doc /* 2 軸走査ミラー：水平はポリゴン、垂直はガルバノ。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '走査周波数Hz' : Real default 10.0;
        part 'ポリゴンミラー' : 'ポリゴンミラー型';
        part 'ガルバノミラー' : 'ガルバノミラー型';
        part 'モータドライバ' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 0.05 [kg] + 'ポリゴンミラー'.mass + 'ガルバノミラー'.mass + 'モータドライバ'.mass;
        attribute '消費電力' : PowerValue = 'ポリゴンミラー'.'消費電力' + 'ガルバノミラー'.'消費電力' + 'モータドライバ'.'消費電力';
    }

    part def 'LiDAR受信部' {
        doc /* 受光部：InGaAs APD アレイと時間ディジタル変換器。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute 'チャネル数' : Integer default 128;
        part 'APDアレイ' : 'APDアレイ型';
        part 'TDC' : '時間デジタル変換器';
        attribute mass :> ISQ::mass = 0.03 [kg] + 'APDアレイ'.mass + 'TDC'.mass;
        attribute '消費電力' : PowerValue = 'APDアレイ'.'消費電力' + 'TDC'.'消費電力';
    }

    part def '長距離LiDAR' :> 'センサ' {
        doc /*
         * 前方長距離 LiDAR（1550 nm）。検知距離 300 m、水平視野 120 度、10 Hz。キャブ屋根の前端中央に付け、
         * 自動運転優先レーンの前方 300 m を見る。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium housing, glass window"; finish = Finish::anodizedAluminum; color = "#30353b"; roughness = 0.4; }
        attribute :>> '検知距離' = 300 [m];
        attribute :>> latency = 0.1 [s];
        attribute :>> 'フレームレートHz' = 10.0;
        attribute :>> 'ハウジング質量' = 0.55 [kg];
        attribute '毎秒点数' : Real default 2400000.0;
        part 'レーザ' : 'LiDARレーザ送信部';
        part 'スキャナ' : 'LiDARスキャナ';
        part '受信側' : 'LiDAR受信部';
        part 'プロセッサ' : 'センサ処理部';
        part '窓' : 'センサ窓';
        part 'ノズル' : '洗浄ノズル';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + 'レーザ'.mass + 'スキャナ'.mass + '受信側'.mass + 'プロセッサ'.mass + '窓'.mass + 'ノズル'.mass;
        attribute :>> '消費電力' = 'レーザ'.'消費電力' + 'スキャナ'.'消費電力' + '受信側'.'消費電力' + 'プロセッサ'.'消費電力' + '窓'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 300.0; }
        port :>> '24V電源' { in :>> current = 1.2 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.15 [m]; :>> width = 0.12 [m]; :>> height = 0.1 [m]; }
        @Budget { powerW = 29.0; latencyMs = 100.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 120.0; verticalDeg = 25.0; rangeM = 300.0; minRangeM = 1.0; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def 'コーナーLiDAR' :> 'センサ' {
        doc /* コーナー LiDAR（905 nm フラッシュ式、ソリッドステート）。キャブ前端と荷箱後端の四隅で死角と隣接車線を覆う。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded polymer housing"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute :>> '検知距離' = 120 [m];
        attribute :>> latency = 0.05 [s];
        attribute :>> 'フレームレートHz' = 20.0;
        part '発光部' : 'VCSELアレイ';
        part '検出器' : 'SPADアレイ';
        part 'プロセッサ' : 'センサ処理部';
        part '窓' : 'センサ窓';
        part 'ノズル' : '洗浄ノズル';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + '発光部'.mass + '検出器'.mass + 'プロセッサ'.mass + '窓'.mass + 'ノズル'.mass;
        attribute :>> '消費電力' = '発光部'.'消費電力' + '検出器'.'消費電力' + 'プロセッサ'.'消費電力' + '窓'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 150.0; }
        port :>> '24V電源' { in :>> current = 0.9 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.12 [m]; :>> height = 0.1 [m]; }
        @Budget { powerW = 21.0; latencyMs = 50.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 120.0; verticalDeg = 30.0; rangeM = 120.0; minRangeM = 0.2; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def 'イメージングレーダ' :> 'センサ' {
        doc /* 前方 4D イメージングレーダ（77 GHz）。雨、霧、水しぶきに強く、トンネル内でも距離と速度を測る。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "radome polymer"; finish = Finish::polymer; color = "#3a3f46"; }
        attribute :>> '検知距離' = 300 [m];
        attribute :>> latency = 0.05 [s];
        attribute :>> 'フレームレートHz' = 20.0;
        attribute '豪雨時検知距離' : LengthValue = '検知距離' * 0.6 {
            doc /* 50 mm/h の強雨での検知距離（晴天の 60 %、メーカ試験値）。SOTIF の誘因条件。 */
        }
        part 'MMIC群' : 'レーダMMIC'[4];
        part 'アンテナ基板' : 'レーダアンテナ基板';
        part 'レーダ処理部' : 'レーダ処理部型';
        part 'レドーム' : 'センサ窓';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + 4 * 'MMIC群'.mass + 'アンテナ基板'.mass + 'レーダ処理部'.mass + 'レドーム'.mass;
        attribute :>> '消費電力' = 4 * 'MMIC群'.'消費電力' + 'レーダ処理部'.'消費電力' + 'レドーム'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 100.0; }
        port :>> '24V電源' { in :>> current = 0.75 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.07 [m]; :>> width = 0.2 [m]; :>> height = 0.15 [m]; }
        @Budget { powerW = 17.0; latencyMs = 50.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 100.0; verticalDeg = 20.0; rangeM = 300.0; minRangeM = 0.5; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def 'コーナーレーダ' :> 'センサ' {
        doc /* コーナーレーダ（77 GHz）。合流と車線変更時の側方車両、追越車両を検知する。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "radome polymer"; finish = Finish::polymer; color = "#3a3f46"; }
        attribute :>> '検知距離' = 160 [m];
        attribute :>> latency = 0.05 [s];
        attribute :>> 'フレームレートHz' = 20.0;
        part 'MMIC群' : 'レーダMMIC'[2];
        part 'アンテナ基板' : 'レーダアンテナ基板';
        part 'レーダ処理部' : 'レーダ処理部型';
        part 'レドーム' : 'センサ窓';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + 2 * 'MMIC群'.mass + 'アンテナ基板'.mass + 'レーダ処理部'.mass + 'レドーム'.mass;
        attribute :>> '消費電力' = 2 * 'MMIC群'.'消費電力' + 'レーダ処理部'.'消費電力' + 'レドーム'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 60.0; }
        port :>> '24V電源' { in :>> current = 0.6 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.09 [m]; :>> width = 0.16 [m]; :>> height = 0.12 [m]; }
        @Budget { powerW = 14.0; latencyMs = 50.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 150.0; verticalDeg = 30.0; rangeM = 160.0; minRangeM = 0.3; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def '前方カメラ型' :> 'センサ' {
        doc /* 前方カメラ（8 MP）。標識、車線、工事規制、信号を認識する。前面ガラスの内側上部に付く。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded polymer housing"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute :>> '検知距離' default 250 [m];
        attribute :>> latency = 0.033 [s];
        attribute :>> 'フレームレートHz' = 30.0;
        attribute :>> 'ハウジング質量' = 0.12 [kg];
        part '撮像素子' : 'イメージセンサ';
        part 'レンズ' : 'カメラレンズ';
        part 'シリアライザ' : '映像シリアライザ';
        part '窓' : 'センサ窓';
        part 'ノズル' : '洗浄ノズル';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + '撮像素子'.mass + 'レンズ'.mass + 'シリアライザ'.mass + '窓'.mass + 'ノズル'.mass;
        attribute :>> '消費電力' = '撮像素子'.'消費電力' + 'シリアライザ'.'消費電力' + '窓'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 400.0; }
        port :>> '24V電源' { in :>> current = 0.4 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.1 [m]; :>> height = 0.08 [m]; }
        @Budget { powerW = 9.1; latencyMs = 33.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 30.0; verticalDeg = 17.0; rangeM = 250.0; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def '周辺監視カメラ' :> 'センサ' {
        doc /* 周辺カメラ（3 MP 広角）。左右の側方と後方を見る。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded polymer housing"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute :>> '検知距離' = 80 [m];
        attribute :>> latency = 0.033 [s];
        attribute :>> 'フレームレートHz' = 30.0;
        attribute :>> 'ハウジング質量' = 0.1 [kg];
        part '撮像素子' : 'イメージセンサ' { :>> '画素数MP' = 3.0; }
        part 'レンズ' : 'カメラレンズ' { :>> '焦点距離' = 0.004 [m]; }
        part 'シリアライザ' : '映像シリアライザ';
        part '窓' : 'センサ窓';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + '撮像素子'.mass + 'レンズ'.mass + 'シリアライザ'.mass + '窓'.mass;
        attribute :>> '消費電力' = '撮像素子'.'消費電力' + 'シリアライザ'.'消費電力' + '窓'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 200.0; }
        port :>> '24V電源' { in :>> current = 0.4 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.1 [m]; :>> width = 0.1 [m]; :>> height = 0.08 [m]; }
        @Budget { powerW = 9.1; latencyMs = 33.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 120.0; verticalDeg = 70.0; rangeM = 80.0; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def '赤外線カメラ型' :> 'センサ' {
        doc /* 遠赤外線サーマルカメラ。夜間、逆光、トンネル出口で歩行者、作業員、落下物を検知する。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded polymer housing"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute :>> '検知距離' = 200 [m];
        attribute :>> latency = 0.033 [s];
        attribute :>> 'フレームレートHz' = 30.0;
        part 'ボロメータ' : 'マイクロボロメータ';
        part 'レンズ' : 'カメラレンズ' { doc /* ゲルマニウムレンズ（遠赤外を透過）。 */ }
        part 'シャッタ' : '赤外線シャッタ';
        part 'シリアライザ' : '映像シリアライザ';
        part '窓' : 'センサ窓';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + 'ボロメータ'.mass + 'レンズ'.mass + 'シャッタ'.mass + 'シリアライザ'.mass + '窓'.mass;
        attribute :>> '消費電力' = 'ボロメータ'.'消費電力' + 'シャッタ'.'消費電力' + 'シリアライザ'.'消費電力' + '窓'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 60.0; }
        port :>> '24V電源' { in :>> current = 0.4 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.12 [m]; :>> width = 0.12 [m]; :>> height = 0.09 [m]; }
        @Budget { powerW = 9.1; latencyMs = 33.0; bus = "lv24a"; }
        @FieldOfView { horizontalDeg = 50.0; verticalDeg = 40.0; rangeM = 200.0; }
        @Safety { asil = Asil::B; isolationGroup = "perception"; }
    }

    part def 'GNSS_IMU型' :> 'センサ' {
        doc /*
         * GNSS/IMU 測位ユニット。デュアルアンテナ RTK で方位も求め、準天頂衛星みちびきの CLAS で
         * センチメータ級の補強を受ける。PPS 出力で gPTP グランドマスタの時刻源になる。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium enclosure"; finish = Finish::metal; color = "#6d737a"; }
        attribute :>> '検知距離' = 0 [m];
        attribute :>> latency = 0.005 [s];
        attribute :>> 'フレームレートHz' = 100.0;
        attribute '位置精度' : LengthValue default 0.03 [m];
        part '主アンテナ' : 'GNSSアンテナ';
        part '副アンテナ' : 'GNSSアンテナ';
        part '受信側' : 'GNSS受信機';
        part 'CLAS受信機' : 'CLAS受信機型';
        part 'IMU' : 'IMUセンサ';
        attribute :>> mass = 'ハウジング質量' + '取付部'.mass + '主アンテナ'.mass + '副アンテナ'.mass + '受信側'.mass + 'CLAS受信機'.mass + 'IMU'.mass;
        attribute :>> '消費電力' = '主アンテナ'.'消費電力' + '副アンテナ'.'消費電力' + '受信側'.'消費電力' + 'CLAS受信機'.'消費電力' + 'IMU'.'消費電力';
        port :>> 'Ethernet端子' { :>> dataRateMbps = 2.0; }
        port :>> '24V電源' { in :>> current = 0.2 [A]; }
        port 'PPS' : '時刻同期ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.9 [m]; :>> width = 0.2 [m]; :>> height = 0.06 [m]; }
        @Budget { powerW = 3.4; latencyMs = 5.0; bus = "lv24a"; }
        @Safety { isolationGroup = "perception"; }
    }

    part def 'ゾーンスイッチ型' {
        doc /* センサ集約用の TSN ゾーンスイッチ。センサ 16 台を 1000BASE-T1 で受け、10GBASE-T1 で計算機へ上げる。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "die cast aluminium case"; finish = Finish::metal; color = "#7a8088"; roughness = 0.5; }
        attribute '通信容量Mbps' : Real default 10000.0;
        attribute 'ホップ遅れ' : DurationValue default 0.0002 [s];
        part 'スイッチチップ' : 'Ethernetスイッチチップ';
        part 'PHY群' : 'Ethernet_PHY型'[8];
        part 'マイコン' : 'マイコン型';
        part '電源管理IC' : '電源管理IC型';
        attribute mass :> ISQ::mass = 0.6 [kg] + 'スイッチチップ'.mass + 8 * 'PHY群'.mass + 'マイコン'.mass + '電源管理IC'.mass;
        attribute '消費電力' : PowerValue = 'スイッチチップ'.'消費電力' + 8 * 'PHY群'.'消費電力' + 'マイコン'.'消費電力' + '電源管理IC'.'消費電力';
        port 'Ethernet端子' : 'Ethernetポート' { :>> 'リンク容量Mbps' = 10000.0; :>> dataRateMbps = 0.0; }
        port 'アップリンク' : 'Ethernetポート' { :>> 'リンク容量Mbps' = 10000.0; :>> dataRateMbps = 0.0; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 0.5 [A]; }
        port 'PTP' : ~'時刻同期ポート';
        @Budget { powerW = 11.3; latencyMs = 0.2; bus = "lv24a"; }
        @Safety { isolationGroup = "perception"; barrier = true; }
    }

    part def '認識センサ群型' {
        doc /*
         * 認識センサ群：前方長距離 LiDAR、コーナー LiDAR 4、前方 4D レーダ、コーナーレーダ 4、
         * 前方カメラ 2、周辺カメラ 3、サーマルカメラ、GNSS/IMU、ゾーンスイッチ。
         * キャブ前面、キャブ屋根、荷箱後端に分散して付ける。全高 3.8 m と全幅 2.5 m の内側に収める。
         */
        @Placement { mode = LayoutMode::fixed; }
        part '前方LiDAR' : '長距離LiDAR' { @Placement { xM = 5.8025; yM = 0.0; zM = 1.105; } }
        part '前左LiDAR' : 'コーナーLiDAR' { @Placement { xM = 5.9025; yM = 1.12; zM = -1.035; yawDeg = 45.0; } }
        part '前右LiDAR' : 'コーナーLiDAR' { @Placement { xM = 5.9025; yM = -1.12; zM = -1.035; yawDeg = -45.0; } }
        part '後左LiDAR' : 'コーナーLiDAR' { @Placement { xM = -5.8975; yM = 1.12; zM = -1.265; yawDeg = 135.0; } }
        part '後右LiDAR' : 'コーナーLiDAR' { @Placement { xM = -5.8975; yM = -1.12; zM = -1.265; yawDeg = -135.0; } }
        part '前方レーダ' : 'イメージングレーダ' { @Placement { xM = 5.9525; yM = 0.0; zM = -1.395; } }
        part '前左レーダ' : 'コーナーレーダ' { @Placement { xM = 5.9125; yM = 1.08; zM = -1.415; yawDeg = 45.0; } }
        part '前右レーダ' : 'コーナーレーダ' { @Placement { xM = 5.9125; yM = -1.08; zM = -1.415; yawDeg = -45.0; } }
        part '後左レーダ' : 'コーナーレーダ' { @Placement { xM = -5.8975; yM = 1.08; zM = -1.495; yawDeg = 135.0; } }
        part '後右レーダ' : 'コーナーレーダ' { @Placement { xM = -5.8975; yM = -1.08; zM = -1.495; yawDeg = -135.0; } }
        part '狭角カメラ' : '前方カメラ型' { @Placement { xM = 5.8825; yM = 0.25; zM = 0.835; } }
        part '広角カメラ' : '前方カメラ型' { :>> '検知距離' = 120 [m]; part :>> 'レンズ' { :>> '焦点距離' = 0.006 [m]; } @Placement { xM = 5.8825; yM = -0.25; zM = 0.835; } }
        part '左側方カメラ' : '周辺監視カメラ' { @Placement { xM = 5.7025; yM = 1.17; zM = 0.785; yawDeg = 90.0; } }
        part '右側方カメラ' : '周辺監視カメラ' { @Placement { xM = 5.7025; yM = -1.17; zM = 0.785; yawDeg = -90.0; } }
        part '後方カメラ' : '周辺監視カメラ' { @Placement { xM = -5.9375; yM = 0.0; zM = 1.485; yawDeg = 180.0; } }
        part '赤外線カメラ' : '赤外線カメラ型' { @Placement { xM = 5.9225; yM = 0.0; zM = -0.835; } }
        part 'GNSS_IMU' : 'GNSS_IMU型' { @Placement { xM = 4.1025; yM = 0.0; zM = 1.525; } }
        part 'センサスイッチ' : 'ゾーンスイッチ型' { @Placement { xM = 3.8025; yM = 0.75; zM = -0.495; } }
        interface '前方LiDARリンク' : 'Ethernetリンク' connect '端A' ::> '前方LiDAR'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '前左LiDARリンク' : 'Ethernetリンク' connect '端A' ::> '前左LiDAR'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '前右LiDARリンク' : 'Ethernetリンク' connect '端A' ::> '前右LiDAR'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '後左LiDARリンク' : 'Ethernetリンク' connect '端A' ::> '後左LiDAR'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '後右LiDARリンク' : 'Ethernetリンク' connect '端A' ::> '後右LiDAR'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '前方レーダリンク' : 'Ethernetリンク' connect '端A' ::> '前方レーダ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '前左レーダリンク' : 'Ethernetリンク' connect '端A' ::> '前左レーダ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '前右レーダリンク' : 'Ethernetリンク' connect '端A' ::> '前右レーダ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '後左レーダリンク' : 'Ethernetリンク' connect '端A' ::> '後左レーダ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '後右レーダリンク' : 'Ethernetリンク' connect '端A' ::> '後右レーダ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '狭角カメラリンク' : 'Ethernetリンク' connect '端A' ::> '狭角カメラ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '広角カメラリンク' : 'Ethernetリンク' connect '端A' ::> '広角カメラ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '左側方カメラリンク' : 'Ethernetリンク' connect '端A' ::> '左側方カメラ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '右側方カメラリンク' : 'Ethernetリンク' connect '端A' ::> '右側方カメラ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '後方カメラリンク' : 'Ethernetリンク' connect '端A' ::> '後方カメラ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface '赤外線カメラリンク' : 'Ethernetリンク' connect '端A' ::> '赤外線カメラ'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        interface 'GNSSリンク' : 'Ethernetリンク' connect '端A' ::> 'GNSS_IMU'.'Ethernet端子' to '端B' ::> 'センサスイッチ'.'Ethernet端子';
        attribute '前方検知距離' : LengthValue = '前方LiDAR'.'検知距離';
        attribute 'センサ数' : Integer = 17;
        attribute '総データ量Mbps' : Real = '前方LiDAR'.'Ethernet端子'.dataRateMbps + '前左LiDAR'.'Ethernet端子'.dataRateMbps + '前右LiDAR'.'Ethernet端子'.dataRateMbps
            + '後左LiDAR'.'Ethernet端子'.dataRateMbps + '後右LiDAR'.'Ethernet端子'.dataRateMbps + '前方レーダ'.'Ethernet端子'.dataRateMbps
            + '前左レーダ'.'Ethernet端子'.dataRateMbps + '前右レーダ'.'Ethernet端子'.dataRateMbps + '後左レーダ'.'Ethernet端子'.dataRateMbps + '後右レーダ'.'Ethernet端子'.dataRateMbps
            + '狭角カメラ'.'Ethernet端子'.dataRateMbps + '広角カメラ'.'Ethernet端子'.dataRateMbps + '左側方カメラ'.'Ethernet端子'.dataRateMbps + '右側方カメラ'.'Ethernet端子'.dataRateMbps
            + '後方カメラ'.'Ethernet端子'.dataRateMbps + '赤外線カメラ'.'Ethernet端子'.dataRateMbps + 'GNSS_IMU'.'Ethernet端子'.dataRateMbps;
        attribute '消費電力' : PowerValue = '前方LiDAR'.'消費電力' + '前左LiDAR'.'消費電力' + '前右LiDAR'.'消費電力' + '後左LiDAR'.'消費電力' + '後右LiDAR'.'消費電力' + '前方レーダ'.'消費電力' + '前左レーダ'.'消費電力' + '前右レーダ'.'消費電力' + '後左レーダ'.'消費電力' + '後右レーダ'.'消費電力' + '狭角カメラ'.'消費電力' + '広角カメラ'.'消費電力' + '左側方カメラ'.'消費電力' + '右側方カメラ'.'消費電力' + '後方カメラ'.'消費電力' + '赤外線カメラ'.'消費電力' + 'GNSS_IMU'.'消費電力' + 'センサスイッチ'.'消費電力';
        attribute mass :> ISQ::mass = '前方LiDAR'.mass + '前左LiDAR'.mass + '前右LiDAR'.mass + '後左LiDAR'.mass + '後右LiDAR'.mass + '前方レーダ'.mass + '前左レーダ'.mass + '前右レーダ'.mass + '後左レーダ'.mass + '後右レーダ'.mass + '狭角カメラ'.mass + '広角カメラ'.mass + '左側方カメラ'.mass + '右側方カメラ'.mass + '後方カメラ'.mass + '赤外線カメラ'.mass + 'GNSS_IMU'.mass + 'センサスイッチ'.mass;
        attribute '上端高さ' : LengthValue = 3.27 [m];
    }

    /* ------------------------------------------------------------ */
    /* 自動運転計算機 */
    /* ------------------------------------------------------------ */

    part def 'アクセル型' {
        doc /* SoC ボード：自動運転 SoC、LPDDR5 DRAM 8 個、TSN スイッチ、PMIC、UFS ストレージ、ブート用フラッシュ。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "FR4 board"; finish = Finish::pcb; color = "#1e4a32"; }
        part 'SoC' : '自動運転SoC';
        part 'DRAM' : 'LPDDRメモリ'[8];
        part 'Ethernetスイッチ' : 'Ethernetスイッチチップ';
        part '電源管理IC' : '電源管理IC型';
        part 'ストレージ' : 'UFSストレージ';
        part 'ブートフラッシュ' : 'フラッシュメモリ';
        attribute mass :> ISQ::mass = 0.25 [kg] + 'SoC'.mass + 8 * 'DRAM'.mass + 'Ethernetスイッチ'.mass + '電源管理IC'.mass + 'ストレージ'.mass + 'ブートフラッシュ'.mass;
        attribute '消費電力' : PowerValue = 'SoC'.'消費電力' + 8 * 'DRAM'.'消費電力' + 'Ethernetスイッチ'.'消費電力' + '電源管理IC'.'消費電力' + 'ストレージ'.'消費電力' + 'ブートフラッシュ'.'消費電力';
    }

    part def 'ホストプロセッサ' {
        doc /* ホストプロセッサ基板：アプリケーションプロセッサと LPDDR5 DRAM 4 個。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "FR4 board"; finish = Finish::pcb; color = "#1e4a32"; }
        part 'CPU' : 'ホストCPU';
        part 'DRAM' : 'LPDDRメモリ'[4];
        attribute mass :> ISQ::mass = 0.1 [kg] + 'CPU'.mass + 4 * 'DRAM'.mass;
        attribute '消費電力' : PowerValue = 'CPU'.'消費電力' + 4 * 'DRAM'.'消費電力';
    }

    part def '計算プラットフォーム' {
        doc /*
         * 主系自動運転計算機（液冷、ASIL B(D)：制動、操舵指令の ASIL D を冗長系と分解した片側）。SoC ボード 2 枚で認識、予測、経路計画を実行し、
         * 安全アイランドが CAN FD で減速、操舵、駆動力の指令を出す。24 V ネット A から給電。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium cold plate chassis"; finish = Finish::anodizedAluminum; color = "#4a5058"; roughness = 0.5; }
        attribute '定格出力' : PowerValue default 800 [W];
        attribute latency : DurationValue default 0.05 [s];
        attribute 'シャシ質量' : MassValue default 9 [kg];
        part 'アクセルA系' : 'アクセル型';
        part 'アクセルB系' : 'アクセル型';
        part 'ホスト' : 'ホストプロセッサ';
        part 'セーフティアイランド' : 'セーフティアイランドコア';
        part '冷却プレート' : '冷却プレート型';
        part '電源ユニット' : '計算機電源';
        attribute mass :> ISQ::mass = 'シャシ質量' + 'アクセルA系'.mass + 'アクセルB系'.mass + 'ホスト'.mass + 'セーフティアイランド'.mass + '冷却プレート'.mass + '電源ユニット'.mass;
        attribute '消費電力' : PowerValue = 'アクセルA系'.'消費電力' + 'アクセルB系'.'消費電力' + 'ホスト'.'消費電力' + 'セーフティアイランド'.'消費電力' + '電源ユニット'.'消費電力';
        port 'Ethernet端子' : 'Ethernetポート' { :>> 'リンク容量Mbps' = 10000.0; :>> dataRateMbps = 50.0; }
        port 'CAN' : 'CANポート' { :>> '負荷率' = 0.3; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 30 [A]; }
        port 'PTP' : ~'時刻同期ポート';
        port '冷却水' : ~'冷却水ポート';
        @Budget { powerW = 645.0; latencyMs = 50.0; bus = "lv24a"; }
        @Safety { asil = Asil::B; isolationGroup = "primary"; failOperational = true; }
    }

    part def 'フォールバックSoC' {
        doc /* 冗長系の SoC（主系と別シリコン）。最小リスク操作に必要な認識と軌道生成だけを行う。 */
        attribute mass :> ISQ::mass default 0.04 [kg];
        attribute '消費電力' : PowerValue default 120 [W];
        attribute tops : Real default 254.0;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.05 [m]; :>> width = 0.05 [m]; :>> height = 0.005 [m]; }
        @Safety { asil = Asil::B; }
    }

    part def 'フォールバック計算機型' {
        doc /*
         * 冗長系（フォールバック）計算機（ASIL B(D)、分解のもう片側）。主系と異なる SoC で、24 V ネット B から給電し、
         * バックボーンスイッチ B に接続する。主系の失陥時に最小リスク操作（MRM）を実行する。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium cold plate chassis"; finish = Finish::anodizedAluminum; color = "#4a5058"; roughness = 0.5; }
        attribute '定格出力' : PowerValue default 300 [W];
        attribute latency : DurationValue default 0.03 [s];
        attribute 'シャシ質量' : MassValue default 5 [kg];
        part 'SoC' : 'フォールバックSoC';
        part 'DRAM' : 'LPDDRメモリ'[4];
        part 'ホスト' : 'ホストプロセッサ';
        part 'セーフティアイランド' : 'セーフティアイランドコア';
        part '冷却プレート' : '冷却プレート型';
        part '電源ユニット' : '計算機電源';
        attribute mass :> ISQ::mass = 'シャシ質量' + 'SoC'.mass + 4 * 'DRAM'.mass + 'ホスト'.mass + 'セーフティアイランド'.mass + '冷却プレート'.mass + '電源ユニット'.mass;
        attribute '消費電力' : PowerValue = 'SoC'.'消費電力' + 4 * 'DRAM'.'消費電力' + 'ホスト'.'消費電力' + 'セーフティアイランド'.'消費電力' + '電源ユニット'.'消費電力';
        port 'Ethernet端子' : 'Ethernetポート' { :>> 'リンク容量Mbps' = 10000.0; :>> dataRateMbps = 30.0; }
        port 'CAN' : 'CANポート' { :>> '負荷率' = 0.2; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 10 [A]; }
        port 'PTP' : ~'時刻同期ポート';
        port '冷却水' : ~'冷却水ポート';
        @Budget { powerW = 249.0; latencyMs = 30.0; bus = "lv24b"; }
        @Safety { asil = Asil::B; isolationGroup = "fallback"; failOperational = true; }
    }

    part def '安全監視装置型' {
        doc /*
         * 安全監視 MCU（ASIL D、ロックステップ）。主系と冗長系のハートビートを監視し、
         * 主系の異常時に冗長系へ制御権を渡す。ネット A と B の両方から給電する。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        attribute 'ハートビート周期' : DurationValue default 0.01 [s];
        attribute 'ハートビートタイムアウト' : DurationValue default 0.03 [s];
        attribute '系統切替時間' : DurationValue default 0.02 [s];
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.5 [kg] + '基板'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力';
        port '主計算機CAN端子' : 'CANポート' { :>> '負荷率' = 0.05; }
        port 'フォールバックCAN端子' : 'CANポート' { :>> '負荷率' = 0.05; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 0.15 [A]; }
        port 'B系24V電源' : ~'24V電源ポート' { in :>> current = 0.15 [A]; }
        @Budget { powerW = 2.5; latencyMs = 20.0; bus = "lv24b"; }
        @Safety { asil = Asil::D; isolationGroup = "fallback"; failOperational = true; barrier = true; }
    }

    part def '時刻同期グランドマスタ' {
        doc /* gPTP グランドマスタ。GNSS の PPS に同期し、全センサと計算機の時刻を 1 マイクロ秒以内にそろえる。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "die cast aluminium case"; finish = Finish::metal; color = "#7a8088"; roughness = 0.5; }
        attribute '同期精度' : DurationValue default 0.0000005 [s];
        attribute 'ホールドオーバー' : DurationValue default 3600 [s];
        part '発振器' : '恒温槽付水晶発振器';
        part 'マイコン' : 'マイコン型';
        part 'PTP用PHY群' : 'Ethernet_PHY型'[4];
        attribute mass :> ISQ::mass = 0.2 [kg] + '発振器'.mass + 'マイコン'.mass + 4 * 'PTP用PHY群'.mass;
        attribute '消費電力' : PowerValue = '発振器'.'消費電力' + 'マイコン'.'消費電力' + 4 * 'PTP用PHY群'.'消費電力';
        port 'PTP' : '時刻同期ポート' { :>> offset = 0.0000005 [s]; }
        port 'PPS入力' : ~'時刻同期ポート';
        port '24V電源' : ~'24V電源ポート' { in :>> current = 0.2 [A]; }
        @Budget { powerW = 4.3; bus = "lv24b"; }
        @Safety { asil = Asil::D; isolationGroup = "fallback"; barrier = true; }
    }

    part def 'バックボーンスイッチ' {
        doc /* 10GBASE-T1 のバックボーンスイッチ（TSN：時刻同期、時間認識シェーパ、フレーム冗長）。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "die cast aluminium case"; finish = Finish::metal; color = "#7a8088"; roughness = 0.5; }
        attribute '通信容量Mbps' : Real default 10000.0;
        attribute 'ホップ遅れ' : DurationValue default 0.0005 [s];
        part 'スイッチチップ' : 'Ethernetスイッチチップ';
        part 'PHY群' : 'Ethernet_PHY型'[12];
        part 'マイコン' : 'マイコン型';
        part '電源管理IC' : '電源管理IC型';
        attribute mass :> ISQ::mass = 1.2 [kg] + 'スイッチチップ'.mass + 12 * 'PHY群'.mass + 'マイコン'.mass + '電源管理IC'.mass;
        attribute '消費電力' : PowerValue = 'スイッチチップ'.'消費電力' + 12 * 'PHY群'.'消費電力' + 'マイコン'.'消費電力' + '電源管理IC'.'消費電力';
        port 'Ethernet端子' : 'Ethernetポート' { :>> 'リンク容量Mbps' = 10000.0; :>> dataRateMbps = 0.0; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 0.6 [A]; }
        @Safety { isolationGroup = "primary"; barrier = true; }
    }

    part def '自動運転計算機ラック' {
        doc /*
         * 自動運転計算機ラック。キャブ後部、仮眠ベッドの下に置く。主系計算機、冗長系計算機、
         * 安全監視 MCU、gPTP グランドマスタ、バックボーンスイッチ A を縦に積む。
         */
        @Material { name = "powder coated steel rack"; finish = Finish::powderCoat; color = "#2d3136"; }
        attribute 'ラック質量' : MassValue default 18 [kg];
        attribute '独立系統数' : Integer default 2;
        part '主計算機' : '計算プラットフォーム';
        part 'フォールバック計算機' : 'フォールバック計算機型';
        part '安全監視装置' : '安全監視装置型';
        part '時刻マスタ' : '時刻同期グランドマスタ';
        part 'ネットワークスイッチ' : 'バックボーンスイッチ';
        attribute '消費電力' : PowerValue = '主計算機'.'消費電力' + 'フォールバック計算機'.'消費電力' + '安全監視装置'.'消費電力' + '時刻マスタ'.'消費電力' + 'ネットワークスイッチ'.'消費電力';
        attribute '判断遅れ' : DurationValue = 'ネットワークスイッチ'.'ホップ遅れ' + '主計算機'.latency;
        attribute 'フォールバック遅れ' : DurationValue = '安全監視装置'.'系統切替時間' + 'フォールバック計算機'.latency;
        attribute '発熱量' : PowerValue = '主計算機'.'消費電力' + 'フォールバック計算機'.'消費電力';
        attribute mass :> ISQ::mass = 'ラック質量' + '主計算機'.mass + 'フォールバック計算機'.mass + '安全監視装置'.mass + '時刻マスタ'.mass + 'ネットワークスイッチ'.mass;
        interface '主計算機データ' : 'Ethernetリンク' connect '端A' ::> '主計算機'.'Ethernet端子' to '端B' ::> 'ネットワークスイッチ'.'Ethernet端子';
        interface '主計算機ハートビート' : 'CANリンク' connect '端A' ::> '主計算機'.'CAN' to '端B' ::> '安全監視装置'.'主計算機CAN端子';
        interface 'フォールバック計算機ハートビート' : 'CANリンク' connect '端A' ::> 'フォールバック計算機'.'CAN' to '端B' ::> '安全監視装置'.'フォールバックCAN端子';
        interface '主計算機PTP' : '時刻同期リンク' connect 'マスタ' ::> '時刻マスタ'.'PTP' to 'スレーブ' ::> '主計算機'.'PTP';
        interface 'フォールバック計算機PTP' : '時刻同期リンク' connect 'マスタ' ::> '時刻マスタ'.'PTP' to 'スレーブ' ::> 'フォールバック計算機'.'PTP';
        item envelope : RectangularCuboid {
            @Envelope { source = EnvelopeSource::stated; hollow = true; wallThicknessM = 0.003; rule = "計算機を縦に積むラック"; }
            :>> length = 0.6 [m];
            :>> width = 0.9 [m];
            :>> height = 0.5 [m];
        }
        @Placement { mode = LayoutMode::stacked; }
        @Safety { asil = Asil::D; isolationGroup = "primary"; barrier = true; }
    }

    /* ------------------------------------------------------------ */
    /* 車両ネットワーク */
    /* ------------------------------------------------------------ */

    part def 'CAN_FDバス' {
        doc /* CAN FD バス（ハーネスと終端）。busLoad はフレーム数とフレーム長から求めたバス負荷率。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "twisted pair harness"; finish = Finish::polymer; color = "#c8742f"; }
        attribute '公称ビットレート' : Real default 500000.0;
        attribute 'データビットレート' : Real default 2000000.0;
        attribute '毎秒フレーム数' : Real default 1200.0;
        attribute 'フレームあたりビット数' : Real default 180.0;
        attribute 'バス負荷率' : Real = '毎秒フレーム数' * 'フレームあたりビット数' / 'データビットレート';
        part '終端抵抗' : 'バス終端抵抗'[2];
        part 'ハーネス' : 'ハーネス区間';
        attribute mass :> ISQ::mass = 0.3 [kg] + 2 * '終端抵抗'.mass + 'ハーネス'.mass;
        port 'ノード' : 'CANポート';
        @Safety { asil = Asil::D; isolationGroup = "chassis"; barrier = true; }
    }

    part def 'セントラルゲートウェイ' {
        doc /*
         * セントラルゲートウェイ。Ethernet バックボーンと、シャシー CAN FD A/B、パワートレイン CAN（J1939）、
         * ボデー CAN の間でルーティングとファイアウォールを担う。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "die cast aluminium case"; finish = Finish::metal; color = "#7a8088"; roughness = 0.5; }
        attribute 'ルーティング遅れ' : DurationValue default 0.0005 [s];
        attribute 'ファイアウォール有効' : Boolean default true { doc /* ドメイン間のステートフルフィルタ（UN R155 附則 5 の対策）。 */ }
        attribute 'SecOC_MACビット数' : Integer default 64 { doc /* 制動、操舵指令の SecOC メッセージ認証コード長（AES-128 CMAC を 64 bit に切り詰め）。 */ }
        attribute 'RXSWIN読出し可' : Boolean default true { doc /* RXSWIN（型式認定に関わるソフトウェア識別番号）を診断で読み出せる（UN R156 7.2.1.1）。 */ }
        attribute '停車中のみ更新' : Boolean default true { doc /* OTA 更新は停車中、駐車ブレーキ作動中だけ実行する（UN R156 7.2.2.1）。 */ }
        attribute 'ロールバック対応' : Boolean default true { doc /* 更新失敗時は直前の版に戻す（A/B 領域）。 */ }
        part '基板' : 'ECU基板';
        part 'スイッチチップ' : 'Ethernetスイッチチップ' { :>> ports = 6; }
        part 'バックボーン用PHY' : 'Ethernet_PHY型';
        part '遠隔支援用PHY' : 'Ethernet_PHY型';
        part '記録装置用PHY' : 'Ethernet_PHY型';
        part '診断用PHY' : 'Ethernet_PHY型';
        part 'シャシCAN_A系トランシーバ' : 'CAN_FDトランシーバ';
        part 'シャシCAN_B系トランシーバ' : 'CAN_FDトランシーバ';
        part 'パワートレインCANトランシーバ' : 'CAN_FDトランシーバ';
        part 'ボデーCANトランシーバ' : 'CAN_FDトランシーバ';
        attribute mass :> ISQ::mass = 0.7 [kg] + '基板'.mass + 'スイッチチップ'.mass + 'バックボーン用PHY'.mass + '遠隔支援用PHY'.mass + '記録装置用PHY'.mass + '診断用PHY'.mass + 'シャシCAN_A系トランシーバ'.mass + 'シャシCAN_B系トランシーバ'.mass + 'パワートレインCANトランシーバ'.mass + 'ボデーCANトランシーバ'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'スイッチチップ'.'消費電力' + 'バックボーン用PHY'.'消費電力' + '遠隔支援用PHY'.'消費電力' + '記録装置用PHY'.'消費電力' + '診断用PHY'.'消費電力' + 'シャシCAN_A系トランシーバ'.'消費電力' + 'シャシCAN_B系トランシーバ'.'消費電力' + 'パワートレインCANトランシーバ'.'消費電力' + 'ボデーCANトランシーバ'.'消費電力';
        port 'Ethernet端子' : 'Ethernetポート' { :>> 'リンク容量Mbps' = 1000.0; :>> dataRateMbps = 20.0; }
        port 'シャシCAN_A系端子' : 'CANポート' { :>> '負荷率' = 0.2; }
        port 'シャシCAN_B系端子' : 'CANポート' { :>> '負荷率' = 0.15; }
        port 'パワートレインCAN端子' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.4; }
        port 'ボデーCAN端子' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.2; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 0.5 [A]; }
        @Budget { powerW = 11.4; latencyMs = 0.5; bus = "lv24a"; }
        @Safety { asil = Asil::D; isolationGroup = "chassis"; barrier = true; }
    }

    part def '車載ネットワーク型' {
        doc /*
         * 車両ネットワーク：10GBASE-T1 TSN バックボーンの B 系スイッチ、セントラルゲートウェイ、
         * シャシー CAN FD A（主系）と B（冗長系）を物理的に分け、パワートレイン CAN とボデー CAN を持つ。
         */
        @Placement { mode = LayoutMode::fixed; }
        part 'B系バックボーンスイッチ' : 'バックボーンスイッチ' { @Placement { xM = 3.441; yM = -0.6148; zM = 0.298; } }
        part 'ゲートウェイ' : 'セントラルゲートウェイ' { @Placement { xM = 5.091; yM = 0.5852; zM = 0.428; } }
        part 'シャシCAN_A系' : 'CAN_FDバス' { :>> '毎秒フレーム数' = 1400.0; @Placement { xM = 0.641; yM = 0.6152; zM = -0.422; } }
        part 'シャシCAN_B系' : 'CAN_FDバス' { :>> '毎秒フレーム数' = 900.0; @Placement { xM = 0.641; yM = -0.3448; zM = -0.422; } }
        part 'パワートレインCAN' : 'CAN_FDバス' { :>> 'データビットレート' = 500000.0; :>> '毎秒フレーム数' = 1100.0; :>> 'フレームあたりビット数' = 130.0; @Placement { xM = 2.941; yM = -0.3448; zM = -0.402; } }
        part 'ボデーCAN' : 'CAN_FDバス' { :>> 'データビットレート' = 500000.0; :>> '毎秒フレーム数' = 400.0; :>> 'フレームあたりビット数' = 130.0; @Placement { xM = -4.859; yM = 0.6152; zM = -0.422; } }
        attribute 'CAN負荷上限' : Real default 0.5;
        attribute '消費電力' : PowerValue = 'B系バックボーンスイッチ'.'消費電力' + 'ゲートウェイ'.'消費電力';
        attribute mass :> ISQ::mass = 'B系バックボーンスイッチ'.mass + 'ゲートウェイ'.mass + 'シャシCAN_A系'.mass + 'シャシCAN_B系'.mass + 'パワートレインCAN'.mass + 'ボデーCAN'.mass;
        interface 'ゲートウェイとバックボーン' : 'Ethernetリンク' connect '端A' ::> 'ゲートウェイ'.'Ethernet端子' to '端B' ::> 'B系バックボーンスイッチ'.'Ethernet端子';
        interface 'ゲートウェイとシャシCAN_A系' : 'CANリンク' connect '端A' ::> 'ゲートウェイ'.'シャシCAN_A系端子' to '端B' ::> 'シャシCAN_A系'.'ノード';
        interface 'ゲートウェイとシャシCAN_B系' : 'CANリンク' connect '端A' ::> 'ゲートウェイ'.'シャシCAN_B系端子' to '端B' ::> 'シャシCAN_B系'.'ノード';
        interface 'ゲートウェイとパワートレインCAN' : 'CANリンク' connect '端A' ::> 'ゲートウェイ'.'パワートレインCAN端子' to '端B' ::> 'パワートレインCAN'.'ノード';
        interface 'ゲートウェイとボデーCAN' : 'CANリンク' connect '端A' ::> 'ゲートウェイ'.'ボデーCAN端子' to '端B' ::> 'ボデーCAN'.'ノード';
    }

    /* ------------------------------------------------------------ */
    /* 24 V 二重電源 */
    /* ------------------------------------------------------------ */

    part def 'オルタネータ型' {
        doc /* エンジン駆動の 24 V オルタネータ（200 A）。ネット A の主電源。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '定格電流' : ElectricCurrentValue default 200 [A];
        attribute '定格出力' : PowerValue = '定格電流' * 24 [V];
        part 'ステータ' : 'オルタネータステータ';
        part 'レギュレータ' : '電圧レギュレータ';
        part '整流器' : '整流ブリッジ';
        attribute mass :> ISQ::mass = 1.5 [kg] + 'ステータ'.mass + 'レギュレータ'.mass + '整流器'.mass;
        port '24V出力' : '24V電源ポート';
        @Budget { powerW = -4800.0; bus = "lv24a"; }
    }

    part def '始動用バッテリ型' {
        doc /* 12 V 鉛バッテリ 2 個の直列（24 V、150 Ah）。始動とネット A のバッファ。 */
        @Placement { mode = LayoutMode::fixed; }
        attribute '容量Ah' : Real default 150.0;
        part 'A系バッテリ' : '鉛蓄電池' { @Placement { xM = 0.0; yM = 0.12; zM = -0.02; } }
        part 'B系バッテリ' : '鉛蓄電池' { @Placement { xM = 0.0; yM = -0.12; zM = -0.02; } }
        attribute mass :> ISQ::mass = 4 [kg] + 'A系バッテリ'.mass + 'B系バッテリ'.mass;
        port '24V出力' : '24V電源ポート';
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.55 [m]; :>> width = 0.5 [m]; :>> height = 0.3 [m]; }
    }

    part def 'バッテリ管理システム' {
        doc /* BMS：セル電圧と温度の監視、SOC 推定、断路コンタクタの制御。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '基板' : 'ECU基板';
        part 'セルモニタ' : 'セルモニタ型';
        part 'コンタクタ' : 'コンタクタ型';
        attribute mass :> ISQ::mass = 0.2 [kg] + '基板'.mass + 'セルモニタ'.mass + 'コンタクタ'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'セルモニタ'.'消費電力';
    }

    part def 'LFPバックアップ電池' {
        doc /* 8 直 LFP バックアップ電池（25.6 V、100 Ah）。ネット B の電源で、ネット A が失陥しても安全系に給電する。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "steel cased LFP module"; finish = Finish::powderCoat; color = "#3d4249"; }
        attribute '容量Ah' : Real default 100.0;
        attribute '公称電圧' : ElectricPotentialValue = 25.6 [V];
        attribute energy : EnergyValue = '公称電圧' * '容量Ah' * (1 [A * h]);
        attribute '最大電流' : ElectricCurrentValue default 100 [A];
        attribute '最大出力' : PowerValue = '公称電圧' * '最大電流';
        part 'セル群' : 'LFPセル'[8];
        part 'BMS' : 'バッテリ管理システム';
        attribute mass :> ISQ::mass = 3 [kg] + 8 * 'セル群'.mass + 'BMS'.mass;
        port '24V出力' : '24V電源ポート' { out :>> voltage = 25.6 [V]; }
        @Budget { powerW = -2560.0; bus = "lv24b"; }
        @Safety { asil = Asil::D; isolationGroup = "fallback"; failOperational = true; }
    }

    abstract part def '電源分配ユニット' {
        doc /* 配電ユニット（PDU）。名前付きの eFuse チャネルで負荷ごとに給電し、短絡をマイクロ秒で切り離す。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded PDU housing"; finish = Finish::polymer; color = "#3a3e44"; }
        attribute '定格電流' : ElectricCurrentValue default 250 [A];
        attribute mass :> ISQ::mass;
        attribute '消費電力' : PowerValue;
        part '制御器' : 'ECU基板';
        port '給電' : ~'24V電源ポート';
        @Safety { asil = Asil::D; isolationGroup = "power"; barrier = true; }
    }

    part def '電源分配ユニットA系' :> '電源分配ユニット' {
        doc /* ネット A の PDU：認識センサ、主系計算機、ネットワーク、操舵、制動、駆動力の A 系統、遠隔監視、記録計、HMI、荷箱、12 V 系。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '前方LiDAR用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 3 [A]; }
        part 'コーナーLiDAR用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 6 [A]; }
        part 'レーダ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 6 [A]; }
        part 'カメラ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 4 [A]; }
        part 'GNSS用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part 'センサスイッチ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part '主計算機用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 40 [A]; }
        part 'A系バックボーン用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part 'ゲートウェイ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part '安全監視装置用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part '操舵用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 40 [A]; }
        part 'ブレーキ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 15 [A]; }
        part 'スロットル用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 3 [A]; }
        part '遠隔支援用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 4 [A]; }
        part '記録装置用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part 'HMI用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 5 [A]; }
        part '計算機冷却用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 15 [A]; }
        part 'ボデー用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 30 [A]; }
        part '系統連系用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 60 [A]; }
        part 'DCDC12V用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 30 [A]; }
        attribute '系統数' : Integer = 20;
        attribute :>> mass = 2.4 [kg] + '制御器'.mass + '前方LiDAR用ヒューズ'.mass + 'コーナーLiDAR用ヒューズ'.mass + 'レーダ用ヒューズ'.mass + 'カメラ用ヒューズ'.mass + 'GNSS用ヒューズ'.mass + 'センサスイッチ用ヒューズ'.mass + '主計算機用ヒューズ'.mass + 'A系バックボーン用ヒューズ'.mass + 'ゲートウェイ用ヒューズ'.mass + '安全監視装置用ヒューズ'.mass + '操舵用ヒューズ'.mass + 'ブレーキ用ヒューズ'.mass + 'スロットル用ヒューズ'.mass + '遠隔支援用ヒューズ'.mass + '記録装置用ヒューズ'.mass + 'HMI用ヒューズ'.mass + '計算機冷却用ヒューズ'.mass + 'ボデー用ヒューズ'.mass + '系統連系用ヒューズ'.mass + 'DCDC12V用ヒューズ'.mass;
        attribute :>> '消費電力' = '制御器'.'消費電力' + '前方LiDAR用ヒューズ'.'消費電力' + 'コーナーLiDAR用ヒューズ'.'消費電力' + 'レーダ用ヒューズ'.'消費電力' + 'カメラ用ヒューズ'.'消費電力' + 'GNSS用ヒューズ'.'消費電力' + 'センサスイッチ用ヒューズ'.'消費電力' + '主計算機用ヒューズ'.'消費電力' + 'A系バックボーン用ヒューズ'.'消費電力' + 'ゲートウェイ用ヒューズ'.'消費電力' + '安全監視装置用ヒューズ'.'消費電力' + '操舵用ヒューズ'.'消費電力' + 'ブレーキ用ヒューズ'.'消費電力' + 'スロットル用ヒューズ'.'消費電力' + '遠隔支援用ヒューズ'.'消費電力' + '記録装置用ヒューズ'.'消費電力' + 'HMI用ヒューズ'.'消費電力' + '計算機冷却用ヒューズ'.'消費電力' + 'ボデー用ヒューズ'.'消費電力' + '系統連系用ヒューズ'.'消費電力' + 'DCDC12V用ヒューズ'.'消費電力';
    }

    part def '電源分配ユニットB系' :> '電源分配ユニット' {
        doc /* ネット B の PDU：フェールオペレーショナル負荷（冗長系計算機、安全監視 MCU、操舵、制動、駆動力の B 系統、バックボーン B、グランドマスタ）。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'フォールバック計算機用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 15 [A]; }
        part '安全監視装置用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part '操舵用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 40 [A]; }
        part 'ブレーキ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 15 [A]; }
        part 'スロットル用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 3 [A]; }
        part 'B系バックボーン用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        part '時刻マスタ用ヒューズ' : '電子ヒューズ' { :>> '遮断電流' = 2 [A]; }
        attribute '系統数' : Integer = 7;
        attribute :>> mass = 1.5 [kg] + '制御器'.mass + 'フォールバック計算機用ヒューズ'.mass + '安全監視装置用ヒューズ'.mass + '操舵用ヒューズ'.mass + 'ブレーキ用ヒューズ'.mass + 'スロットル用ヒューズ'.mass + 'B系バックボーン用ヒューズ'.mass + '時刻マスタ用ヒューズ'.mass;
        attribute :>> '消費電力' = '制御器'.'消費電力' + 'フォールバック計算機用ヒューズ'.'消費電力' + '安全監視装置用ヒューズ'.'消費電力' + '操舵用ヒューズ'.'消費電力' + 'ブレーキ用ヒューズ'.'消費電力' + 'スロットル用ヒューズ'.'消費電力' + 'B系バックボーン用ヒューズ'.'消費電力' + '時刻マスタ用ヒューズ'.'消費電力';
    }

    part def '電源系統分離器' {
        doc /* ネット間アイソレータ（理想ダイオード結合）。平常時は A から B を充電し、どちらかが短絡すると 100 マイクロ秒以内に切り離す。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '分離時間' : DurationValue default 0.0001 [s];
        part 'スイッチ群' : 'パワーMOSFET'[4];
        part '運転者' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 0.6 [kg] + 4 * 'スイッチ群'.mass + '運転者'.mass;
        port 'A系電源' : ~'24V電源ポート';
        port 'B系電源' : '24V電源ポート';
        @Safety { asil = Asil::D; isolationGroup = "power"; barrier = true; failOperational = true; }
    }

    part def 'DCDC24V12V変換器' {
        doc /* 24 V から 12 V への DC-DC コンバータ。ETC 2.0 車載器、ラジオなど 12 V 機器用。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '定格出力' : PowerValue default 600 [W];
        part '電力段' : 'DCDC電力段';
        part '制御器' : 'ECU基板';
        part '出力フィルタ' : '出力フィルタ型';
        attribute mass :> ISQ::mass = 0.8 [kg] + '電力段'.mass + '制御器'.mass + '出力フィルタ'.mass;
        port '24V入力' : ~'24V電源ポート';
        port '24V出力' : '24V電源ポート' { out :>> voltage = 12 [V]; }
        @Budget { powerW = -600.0; bus = "lv12"; }
    }

    part def '二重系電源システム' {
        doc /*
         * 24 V 二重電源系。ネット A（オルタネータと始動用鉛バッテリ）とネット B（LFP バックアップ電池）、
         * 各ネットの PDU、ネット間アイソレータ、12 V 系。安全上重要な負荷（制動、操舵、冗長系計算機、
         * 安全監視 MCU）は A と B の両方から給電され、片側が失陥しても動作を続ける。
         */
        @Placement { mode = LayoutMode::fixed; }
        attribute '電源系統数' : Integer default 2;
        part 'オルタネータ' : 'オルタネータ型' { @Placement { xM = 2.1125; yM = -0.415; zM = -0.4537; } }
        part '始動用バッテリ' : '始動用バッテリ型' { @Placement { xM = -1.5375; yM = -0.715; zM = -0.6537; } }
        part 'バックアップ電池' : 'LFPバックアップ電池' { @Placement { xM = -2.9375; yM = -0.745; zM = -0.6337; } }
        part 'A系電源分配ユニット' : '電源分配ユニットA系' { @Placement { xM = 1.3125; yM = 0.855; zM = 0.7963; } }
        part 'B系電源分配ユニット' : '電源分配ユニットB系' { :>> '定格電流' = 150 [A]; @Placement { xM = 1.3125; yM = -0.645; zM = 0.7963; } }
        part '系統分離器' : '電源系統分離器' { @Placement { xM = 1.3125; yM = 0.855; zM = 0.5963; } }
        part 'DCDC12V' : 'DCDC24V12V変換器' { @Placement { xM = 2.9625; yM = 0.905; zM = 0.3463; } }
        attribute 'A系供給' : PowerValue = 'オルタネータ'.'定格出力';
        attribute 'B系供給' : PowerValue = 'バックアップ電池'.'最大出力';
        attribute mass :> ISQ::mass = 'オルタネータ'.mass + '始動用バッテリ'.mass + 'バックアップ電池'.mass + 'A系電源分配ユニット'.mass + 'B系電源分配ユニット'.mass + '系統分離器'.mass + 'DCDC12V'.mass;
        interface 'オルタネータからA系へ' : '24V給電線' connect supplier ::> 'オルタネータ'.'24V出力' to '負荷' ::> 'A系電源分配ユニット'.'給電';
        interface 'スタータとA系' : '24V給電線' connect supplier ::> '始動用バッテリ'.'24V出力' to '負荷' ::> 'A系電源分配ユニット'.'給電';
        interface 'バックアップ電池からB系へ' : '24V給電線' connect supplier ::> 'バックアップ電池'.'24V出力' to '負荷' ::> 'B系電源分配ユニット'.'給電';
        interface '系統連系' : '24V給電線' connect supplier ::> 'A系電源分配ユニット'.'系統連系用ヒューズ'.'負荷側' to '負荷' ::> '系統分離器'.'A系電源';
        interface 'B系充電' : '24V給電線' connect supplier ::> '系統分離器'.'B系電源' to '負荷' ::> 'B系電源分配ユニット'.'給電';
        interface '12V給電' : '24V給電線' connect supplier ::> 'A系電源分配ユニット'.'DCDC12V用ヒューズ'.'負荷側' to '負荷' ::> 'DCDC12V'.'24V入力';
    }

    /* ------------------------------------------------------------ */
    /* 熱マネジメント */
    /* ------------------------------------------------------------ */

    part def 'ラジエータ型' {
        doc /* エンジン冷却ラジエータ。前面グリルの奥、キャブ下に置き、インタークーラとファンを一体にする。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium core"; finish = Finish::metal; color = "#8a8f95"; roughness = 0.6; }
        attribute '放熱量' : PowerValue default 230 [kW];
        part 'コア' : 'ラジエータコア';
        part 'ファン' : 'エンジンファン';
        part 'インタークーラ' : 'インタークーラ型';
        attribute mass :> ISQ::mass = 6 [kg] + 'コア'.mass + 'ファン'.mass + 'インタークーラ'.mass;
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.4 [m]; :>> width = 1.0 [m]; :>> height = 0.85 [m]; }
    }

    part def '冷却水ポンプ' {
        doc /* 電動冷却水ポンプ：ブラシレスモータとドライバ。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '流量Lmin' : Real default 25.0;
        part 'モータ' : 'ポンプモータ';
        part '運転者' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 0.5 [kg] + 'モータ'.mass + '運転者'.mass;
        attribute '消費電力' : PowerValue = 'モータ'.'消費電力' + '運転者'.'消費電力';
    }

    part def '液空熱交換器' {
        doc /* 計算機の熱を外気へ捨てる熱交換器（ファン 2 台）。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute capacity : PowerValue default 1800 [W];
        part 'ファン群' : '熱交換器ファン'[2];
        attribute mass :> ISQ::mass = 4 [kg] + 2 * 'ファン群'.mass;
        attribute '消費電力' : PowerValue = 2 * 'ファン群'.'消費電力';
    }

    part def '計算機冷却ループ型' {
        doc /*
         * 計算機冷却ループ。電動ポンプ 2 台（冗長）、熱交換器、リザーバ、温度センサで主系と冗長系の
         * コールドプレートを冷やす。排熱能力は計算機の発熱を上回ること。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "aluminium exchanger"; finish = Finish::metal; color = "#9aa0a7"; }
        attribute '供給温度C' : Real default 35.0;
        part 'A系ポンプ' : '冷却水ポンプ';
        part 'B系ポンプ' : '冷却水ポンプ';
        part '熱交換器' : '液空熱交換器';
        part 'タンク' : '冷却水リザーバ';
        part '供給圧センサ' : '冷却水温センサ';
        part '戻り側センサ' : '冷却水温センサ';
        attribute '放熱能力' : PowerValue = '熱交換器'.capacity;
        attribute mass :> ISQ::mass = 3 [kg] + 'A系ポンプ'.mass + 'B系ポンプ'.mass + '熱交換器'.mass + 'タンク'.mass + '供給圧センサ'.mass + '戻り側センサ'.mass;
        attribute '消費電力' : PowerValue = 'A系ポンプ'.'消費電力' + 'B系ポンプ'.'消費電力' + '熱交換器'.'消費電力' + '供給圧センサ'.'消費電力' + '戻り側センサ'.'消費電力';
        port '供給' : '冷却水ポート';
        port '24V電源' : ~'24V電源ポート' { in :>> current = 10 [A]; }
        @Budget { powerW = 362.0; bus = "lv24a"; }
    }

    part def '熱管理システム' {
        doc /* 熱マネジメント：エンジン冷却ラジエータと計算機の液冷ループ。キャブ空調はキャブ側に持つ。 */
        @Placement { mode = LayoutMode::fixed; }
        part 'ラジエータ' : 'ラジエータ型' { @Placement { xM = 0.5; yM = 0.0; zM = -0.225; } }
        part '計算機冷却ループ' : '計算機冷却ループ型' { @Placement { xM = -0.6; yM = 0.0; zM = 0.525; } }
        attribute mass :> ISQ::mass = 'ラジエータ'.mass + '計算機冷却ループ'.mass;
        attribute '消費電力' : PowerValue = '計算機冷却ループ'.'消費電力';
    }

    /* ------------------------------------------------------------ */
    /* 遠隔監視、路車間通信、運行記録 */
    /* ------------------------------------------------------------ */

    part def '携帯通信モデム' {
        doc /* 5G NR モデム：モデムチップとアンテナ 4 本。2 台を異なる通信事業者に接続する。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'チップ' : 'モデムチップ';
        part 'アンテナ群' : '携帯通信アンテナ'[4];
        attribute mass :> ISQ::mass = 0.3 [kg] + 'チップ'.mass + 4 * 'アンテナ群'.mass;
        attribute '消費電力' : PowerValue = 'チップ'.'消費電力' + 4 [W];
        port 'セル' : '携帯通信ポート';
    }

    part def 'ITS_Connectユニット' {
        doc /* 760 MHz 帯 ITS 通信ユニット。合流支援情報、先読み情報、緊急車両の接近を受け取る。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '無線機' : 'ITS無線機';
        part 'アンテナ' : 'パッチアンテナ';
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.2 [kg] + '無線機'.mass + 'アンテナ'.mass + '基板'.mass;
        attribute '消費電力' : PowerValue = '無線機'.'消費電力' + '基板'.'消費電力';
        port '無線端子' : 'V2Xポート';
    }

    part def 'ETC2_0車載器' {
        doc /* ETC 2.0 車載器。料金収受と、路側機からの渋滞、規制、落下物情報を受け取る。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'DSRC' : 'DSRCモジュール';
        part 'アンテナ' : 'パッチアンテナ';
        part '基板' : 'ECU基板';
        attribute mass :> ISQ::mass = 0.15 [kg] + 'DSRC'.mass + 'アンテナ'.mass + '基板'.mass;
        attribute '消費電力' : PowerValue = 'DSRC'.'消費電力' + '基板'.'消費電力';
        port '無線端子' : 'V2Xポート' { :>> '搬送波MHz' = 5800.0; :>> rangeM = 30.0; }
    }

    part def '遠隔監視ユニット' {
        doc /*
         * 遠隔監視（テレマティクス）ユニット。異なる通信事業者の 5G モデム 2 台で遠隔監視センターにつながり、
         * 前方映像と車両状態を送る。遠隔運転ではなく、運行管理者による監視、経路の承認、判断支援を受ける（L4）。
         * 760 MHz 帯 ITS 通信と ETC 2.0 で路側の情報も受け取る。キャブ屋根後部に付く。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded telematics housing"; finish = Finish::polymer; color = "#2f3339"; }
        attribute '符号化遅れ' : DurationValue = 'エンコーダ'.'符号化遅れ';
        attribute 'TLS有効' : Boolean default true { doc /* 遠隔監視センターとの通信は相互認証 TLS 1.3（UN R155）。 */ }
        attribute 'リンク遅れ' : DurationValue = 'A系モデム'.'セル'.'往復時間' + '符号化遅れ';
        attribute 'アップリンクMbps' : Real = 'A系モデム'.'セル'.'アップリンクMbps' + 'B系モデム'.'セル'.'アップリンクMbps';
        part 'A系モデム' : '携帯通信モデム';
        part 'B系モデム' : '携帯通信モデム';
        part 'エンコーダ' : '映像エンコーダ';
        part 'ITS_Connect' : 'ITS_Connectユニット';
        part 'ETC2_0' : 'ETC2_0車載器';
        attribute mass :> ISQ::mass = 1.0 [kg] + 'A系モデム'.mass + 'B系モデム'.mass + 'エンコーダ'.mass + 'ITS_Connect'.mass + 'ETC2_0'.mass;
        attribute '消費電力' : PowerValue = 'A系モデム'.'消費電力' + 'B系モデム'.'消費電力' + 'エンコーダ'.'消費電力' + 'ITS_Connect'.'消費電力' + 'ETC2_0'.'消費電力';
        port 'アップリンク' : '携帯通信ポート';
        port 'Ethernet端子' : 'Ethernetポート' { :>> dataRateMbps = 25.0; }
        port '24V電源' : ~'24V電源ポート' { in :>> current = 1.5 [A]; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.5 [m]; :>> width = 0.35 [m]; :>> height = 0.08 [m]; }
        @Budget { powerW = 32.0; bus = "lv24a"; }
        @Safety { asil = Asil::QM; isolationGroup = "body"; }
    }

    part def 'デジタルタコグラフ' {
        doc /* デジタル式運行記録計（デジタコ）。速度、距離、時間、急操作、位置を記録し、運行管理者へ送る。 */
        @Placement { mode = LayoutMode::connectivity; }
        attribute '速度距離時間を記録' : Boolean default true;
        attribute '保持期間' : DurationValue default 31536000 [s] { doc /* 記録の保存 1 年（貨物自動車運送事業輸送安全規則 第 9 条）。 */ }
        part '基板' : 'ECU基板';
        part 'Gセンサ' : '3軸加速度計';
        part 'ストレージ' : '記録装置ストレージ';
        part 'GNSS' : 'GNSS受信機';
        attribute mass :> ISQ::mass = 0.3 [kg] + '基板'.mass + 'Gセンサ'.mass + 'ストレージ'.mass + 'GNSS'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'Gセンサ'.'消費電力' + 'ストレージ'.'消費電力' + 'GNSS'.'消費電力';
    }

    part def '自動運行データ記録装置' {
        doc /* 作動状態記録装置。自動運行装置の作動状態、引継ぎ指令、MRC の発生を時刻付きで記録する。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '基板' : 'ECU基板';
        part 'ストレージ' : '記録装置ストレージ';
        attribute '保持期間' : DurationValue default 15552000 [s];
        attribute mass :> ISQ::mass = 0.2 [kg] + '基板'.mass + 'ストレージ'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'ストレージ'.'消費電力';
        @Safety { asil = Asil::B; isolationGroup = "body"; }
    }

    part def '運行記録装置' {
        doc /* 運行記録系：デジタル式運行記録計、作動状態記録装置、ドライブレコーダカメラ 2 台。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded recorder housing"; finish = Finish::polymer; color = "#24272b"; }
        part 'タコグラフ' : 'デジタルタコグラフ';
        part '自動運行装置作動状態記録装置' : '自動運行データ記録装置';
        part '前方カメラ' : 'ドライブレコーダカメラ';
        part '室内カメラ' : 'ドライブレコーダカメラ';
        attribute mass :> ISQ::mass = 'タコグラフ'.mass + '自動運行装置作動状態記録装置'.mass + '前方カメラ'.mass + '室内カメラ'.mass;
        attribute '消費電力' : PowerValue = 'タコグラフ'.'消費電力' + '自動運行装置作動状態記録装置'.'消費電力' + '前方カメラ'.'消費電力' + '室内カメラ'.'消費電力';
        port '24V電源' : ~'24V電源ポート' { in :>> current = 0.6 [A]; }
        port 'CAN' : 'CANポート' { :>> '負荷率' = 0.05; }
        item envelope : RectangularCuboid { @Envelope { source = EnvelopeSource::stated; } :>> length = 0.25 [m]; :>> width = 0.25 [m]; :>> height = 0.1 [m]; }
        @Budget { powerW = 13.0; bus = "lv24a"; }
    }

    /* ------------------------------------------------------------ */
    /* ウイング荷箱 */
    /* ------------------------------------------------------------ */

    part def '荷室型' {
        doc /*
         * 荷室（積載空間）。内のり長さ 8.81 m、幅 2.30 m、高さ 2.55 m。T11 型パレット（1.1 m 角）を
         * 2 列 8 段の 16 枚積める。最大積載量は 13.6 t。
         */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "cargo envelope"; finish = Finish::translucentPolymer; color = "#f2c14e"; transmission = 0.7; }
        attribute '内寸長さ' : LengthValue default 8.81 [m];
        attribute '内寸幅' : LengthValue default 2.3 [m];
        attribute '内寸高さ' : LengthValue default 2.55 [m];
        attribute '最大積載量' : MassValue default 13600 [kg];
        attribute '荷室容積' : VolumeValue = '内寸長さ' * '内寸幅' * '内寸高さ';
        part '左ラッシングレール' : 'ラッシングレール' { @Placement { xM = 0.0; yM = 1.12; zM = -0.9; } }
        part '右ラッシングレール' : 'ラッシングレール' { @Placement { xM = 0.0; yM = -1.12; zM = -0.9; } }
        part 'モニタ' : '荷室モニタ';
        attribute mass :> ISQ::mass = '左ラッシングレール'.mass + '右ラッシングレール'.mass + 'モニタ'.mass;
        attribute '消費電力' : PowerValue = 'モニタ'.'消費電力';
        item envelope : RectangularCuboid {
            @Envelope { source = EnvelopeSource::computed; rule = "荷室の内のり"; }
            :>> length = '内寸長さ';
            :>> width = '内寸幅';
            :>> height = '内寸高さ';
        }
    }

    part def '油圧パワーユニット型' {
        doc /* ウイング用油圧パワーユニット：ポンプモータ、ギヤポンプ、作動油タンク。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'モータ' : 'ポンプモータ' { :>> '消費電力' = 2000 [W]; }
        part 'ポンプ' : '油圧ポンプ';
        part 'タンク' : '作動油タンク';
        attribute mass :> ISQ::mass = 3 [kg] + 'モータ'.mass + 'ポンプ'.mass + 'タンク'.mass;
        attribute '消費電力' : PowerValue = 'モータ'.'消費電力';
    }

    part def 'ボデーコントローラ' {
        doc /* 荷箱コントローラ：ウイング開閉の順序制御、ドア施錠、荷室照明、ボデー CAN。 */
        @Placement { mode = LayoutMode::connectivity; }
        @Material { name = "moulded ECU enclosure"; finish = Finish::polymer; color = "#2b2f35"; }
        part '基板' : 'ECU基板';
        part 'リレードライバ' : 'ゲートドライバ型';
        attribute mass :> ISQ::mass = 0.4 [kg] + '基板'.mass + 'リレードライバ'.mass;
        attribute '消費電力' : PowerValue = '基板'.'消費電力' + 'リレードライバ'.'消費電力';
        port 'CAN' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.1; }
    }

    part def 'ウイング油圧装置型' {
        doc /* ウイング開閉の油圧系（荷箱前部の区画）：パワーユニット、前側シリンダ 2 本、荷箱コントローラ。後側シリンダ 2 本は荷箱後端の門構えに付く。物流拠点での荷役時に使う。 */
        @Placement { mode = LayoutMode::fixed; }
        attribute '開時間' : DurationValue default 25 [s];
        part '油圧パワーユニット' : '油圧パワーユニット型' { @Placement { xM = 0.0; yM = 0.3725; zM = -1.05; } }
        part '前左シリンダ' : 'ウイングシリンダ' { @Placement { xM = 0.05; yM = 0.2225; zM = 0.55; } }
        part '前右シリンダ' : 'ウイングシリンダ' { @Placement { xM = 0.05; yM = -0.3775; zM = 0.55; } }
        part '制御器' : 'ボデーコントローラ' { @Placement { xM = 0.0; yM = -0.5275; zM = -0.85; } }
        interface '前左' : '油圧配管' connect 'ポンプ' ::> '油圧パワーユニット'.'ポンプ'.'作動油出口' to 'アクチュエータ' ::> '前左シリンダ'.'作動油入口';
        interface '前右' : '油圧配管' connect 'ポンプ' ::> '油圧パワーユニット'.'ポンプ'.'作動油出口' to 'アクチュエータ' ::> '前右シリンダ'.'作動油入口';
        attribute mass :> ISQ::mass = '油圧パワーユニット'.mass + '前左シリンダ'.mass + '前右シリンダ'.mass + '制御器'.mass;
        attribute '消費電力' : PowerValue = '制御器'.'消費電力';
    }

    part def '後扉一式' {
        doc /* 観音開きのリヤドア 2 枚と開閉、施錠の検知スイッチ。 */
        @Placement { mode = LayoutMode::fixed; }
        part '左扉' : '後扉型' { @Placement { xM = 0.0; yM = 0.575; zM = -0.025; } }
        part '右扉' : '後扉型' { @Placement { xM = 0.0; yM = -0.575; zM = -0.025; } }
        part '左センサ' : '扉センサ' { @Placement { xM = 0.0; yM = 0.1; zM = 1.215; } }
        part '右センサ' : '扉センサ' { @Placement { xM = 0.0; yM = -0.1; zM = 1.215; } }
        attribute mass :> ISQ::mass = '左扉'.mass + '右扉'.mass + '左センサ'.mass + '右センサ'.mass;
        attribute '消費電力' : PowerValue = '左センサ'.'消費電力' + '右センサ'.'消費電力';
    }

    part def '荷室モニタ' {
        doc /* 荷室監視：床下ロードセル 4 個、温度センサ、荷崩れ検知カメラ。無人運行中の積荷状態を遠隔監視センターへ送る。 */
        @Placement { mode = LayoutMode::connectivity; }
        part '荷重センサ群' : '床荷重センサ'[4];
        part '温度センサ部' : '荷室温度センサ';
        part 'カメラ' : '荷室カメラ';
        attribute mass :> ISQ::mass = 4 * '荷重センサ群'.mass + '温度センサ部'.mass + 'カメラ'.mass;
        attribute '消費電力' : PowerValue = 4 * '荷重センサ群'.'消費電力' + '温度センサ部'.'消費電力' + 'カメラ'.'消費電力';
    }

    part def 'ウイングボデー' {
        doc /*
         * アルミウイング荷箱（ウイングボデー）。外のり長さ 9.48 m、幅 2.49 m、高さ 2.78 m。床面はシャシー
         * フレーム上（地上 1.0 m）にあり、荷箱上面が車両の最高点（3.78 m）になる。側面パネルは屋根中央の
         * ヒンジでガルウイング状に開き、フォークリフトで側方から荷役できる。前部に油圧ユニットの区画を持つ。
         */
        @Placement { mode = LayoutMode::fixed; }
        @Material { name = "aluminium wing panels, white"; finish = Finish::paint; color = "#f3f4f2"; roughness = 0.35; }
        attribute 'ボデー長' : LengthValue default 9.48 [m];
        attribute 'ボデー幅' : LengthValue default 2.49 [m];
        attribute 'ボデー高さ' : LengthValue default 2.78 [m];
        attribute '構造質量' : MassValue default 1900 [kg];
        part '荷室' : '荷室型' { @Placement { xM = -0.155; yM = 0.0; zM = 0.005; } }
        part '左ウイング' : 'ウイングパネル' { @Placement { xM = -0.155; yM = 1.18; zM = 0.05; } }
        part '右ウイング' : 'ウイングパネル' { @Placement { xM = -0.155; yM = -1.18; zM = 0.05; } }
        part 'ウイング油圧装置' : 'ウイング油圧装置型' { @Placement { xM = 4.475; yM = 0.0775; zM = 0.05; } }
        part '後左ウイングシリンダ' : 'ウイングシリンダ' { @Placement { xM = -4.61; yM = 0.3; zM = 0.6; } }
        part '後右ウイングシリンダ' : 'ウイングシリンダ' { @Placement { xM = -4.61; yM = -0.3; zM = 0.6; } }
        part '後扉' : '後扉一式' { @Placement { xM = -4.68; yM = 0.0; zM = 0.025; } }
        part '荷室灯前' : '荷室灯'[2] { @Placement { xM = 2.0; yM = 0.6; zM = 1.31; } }
        part '荷室灯後' : '荷室灯'[2] { @Placement { xM = -2.3; yM = 0.6; zM = 1.31; } }
        attribute mass :> ISQ::mass = '構造質量' + '荷室'.mass + '左ウイング'.mass + '右ウイング'.mass + 'ウイング油圧装置'.mass + '後左ウイングシリンダ'.mass + '後右ウイングシリンダ'.mass + '後扉'.mass + 2 * '荷室灯前'.mass + 2 * '荷室灯後'.mass;
        attribute '消費電力' : PowerValue = 'ウイング油圧装置'.'消費電力' + '後扉'.'消費電力' + 2 * '荷室灯前'.'消費電力' + 2 * '荷室灯後'.'消費電力' + '荷室'.'消費電力';
        interface '後左ウイング油圧' : '油圧配管' connect 'ポンプ' ::> 'ウイング油圧装置'.'油圧パワーユニット'.'ポンプ'.'作動油出口' to 'アクチュエータ' ::> '後左ウイングシリンダ'.'作動油入口';
        interface '後右ウイング油圧' : '油圧配管' connect 'ポンプ' ::> 'ウイング油圧装置'.'油圧パワーユニット'.'ポンプ'.'作動油出口' to 'アクチュエータ' ::> '後右ウイングシリンダ'.'作動油入口';
        port '取付部' : ~'ボデー取付ポート';
        port '24V電源' : ~'24V電源ポート' { in :>> current = 3 [A]; }
        port 'CAN' : 'CANポート' { :>> 'ビットレート' = 500000.0; :>> '負荷率' = 0.1; }
        item envelope : RectangularCuboid {
            @Envelope { source = EnvelopeSource::computed; hollow = true; wallThicknessM = 0.04; rule = "荷箱外のり長さ x 幅 x 高さ"; }
            :>> length = 'ボデー長';
            :>> width = 'ボデー幅';
            :>> height = 'ボデー高さ';
        }
        item box : Block {
            doc /* 荷箱本体。 */
            :>> length = 'ボデー長';
            :>> width = 'ボデー幅';
            :>> height = 'ボデー高さ';
        }
        item 'ルーフヒンジ' : Block {
            doc /* 屋根中央のウイングヒンジ（センタービーム）。 */
            :>> z = 'ボデー高さ' / 2 + 0.01 [m];
            :>> length = 'ボデー長' - 0.1 [m];
            :>> width = 0.12 [m];
            :>> height = 0.02 [m];
        }
        item 'サブフレーム' : Block {
            doc /* 縦根太（サブフレーム）。 */
            :>> z = -'ボデー高さ' / 2 - 0.0 [m];
            :>> y = 0.42 [m];
            :>> length = 'ボデー長' - 0.2 [m];
            :>> width = 0.08 [m];
            :>> height = 0.02 [m];
            :>> mirror = MirrorPlane::xz;
        }
        item 'ドアハンドル' : Handle {
            :>> face = Face::rear;
            :>> u = 0.6 [m];
            :>> v = 0.0 [m];
            :>> width = 0.3 [m];
            :>> height = 1.6 [m];
            :>> label = "後扉ロックロッド";
        }
        item '側面標識' : Marking {
            :>> face = Face::left;
            :>> u = 0.0 [m];
            :>> v = 0.3 [m];
            :>> width = 6.0 [m];
            :>> height = 0.8 [m];
            :>> label = "L4 自動運転物流";
        }
        @Safety { asil = Asil::QM; isolationGroup = "body"; }
    }

}

// The C file names cited by @SourceTrace (bbw_main.c, bbw_can.c and so on) belong to a
// fictional supplier source tree made up for this example; they trace no real product.
package 'ブレーキECUリバースモデル' {
    doc /*
     * BBW-24 ブレーキバイワイヤ ECU 組込みソフトウェアのリバースモデル。
     * 入力はレガシー C ソース ./brake_ecu/（bbw_main.c, bbw_state.c/.h, bbw_can.c/.h,
     * bbw_diag.c/.h, bbw_cfg.h, bbw_hal.h）。コードを正とし、コメントやヘッダと
     * 食い違う箇所はコードの動作をモデル化して、相違を comment 要素に記録した。
     * 各要素の @SourceTrace と doc に出典の file:line を示す。
     */
    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import MBEstudio::*;
    private import 'L4自動運転大型キャブオーバー車'::*;

    /* ------------------------------------------------------------ */
    /* Trace metadata                                                */
    /* ------------------------------------------------------------ */

    metadata def SourceTrace {
        doc /* ソースコードへのトレースリンク。file はファイル名、line は 1 始まりの行番号、symbol は C のシンボル名。 */
        attribute file : String;
        attribute line : Integer;
        attribute symbol : String;
    }

    /* ------------------------------------------------------------ */
    /* CAN signal and message definitions                            */
    /* ------------------------------------------------------------ */

    item def 'CAN信号' {
        doc /*
         * CAN FD フレーム内の 1 信号。startBit と bitLength はインテル（リトルエンディアン）
         * ビット番号（bbw_can.h:7）。物理値 = raw * factor + offset。minimum/maximum は
         * コードが実際に扱う物理範囲、unit は物理単位の表記。
         */
        @SourceTrace { file = "bbw_can.h"; line = 7; symbol = "byte order little endian"; }
        attribute '開始ビット' : Integer;
        attribute 'ビット長' : Integer;
        attribute factor : Real;
        attribute offset : Real;
        attribute '最小値' : Real;
        attribute '最大値' : Real;
        attribute unit : String;
    }

    enum def 'BBW_XBRモード' {
        doc /* XBR 指令のモード（bbw_can.h:40-47 BbwXbrMode_t）。none=0, engage=1, active=2, disengage=3, mrc=4。active と none は状態遷移では参照されない。 */
        @SourceTrace { file = "bbw_can.h"; line = 40; symbol = "BbwXbrMode_t"; }
        enum 'なし';
        enum '係合';
        enum '作動';
        enum '解除';
        enum 'MRC';
    }

    enum def 'BBW状態' {
        doc /* 動作モード（bbw_state.h:11-19 BbwState_t）。INIT=0, STANDBY=1, AUTONOMOUS_ACTIVE=2, DEGRADED_SINGLE_CHANNEL=3, MRC_STOP=4, FAULT=5。STATUS フレームの byte1 上位 4 bit で送信。 */
        @SourceTrace { file = "bbw_state.h"; line = 11; symbol = "BbwState_t"; }
        enum '初期化';
        enum '待機';
        enum '自動運転中';
        enum '片系縮退';
        enum 'MRC停止';
        enum '故障';
    }

    port def 'CANメッセージポート' {
        doc /*
         * CAN FD メッセージ 1 本の端点（11 bit ID、DLC 8、公称 500 kbit/s、データ相 2 Mbit/s）。
         * bbw_can.h:6, bbw_can.c:62 HAL_CanFdInit(500000, 2000000)。e2eProtected は E2E 保護の有無。
         */
        @SourceTrace { file = "bbw_can.h"; line = 6; symbol = "CAN FD message layout"; }
        attribute 'CAN_ID' : Integer default 0;
        attribute 'DLC' : Integer default 8;
        attribute '周期' : DurationValue default 0.01 [s];
        attribute '公称ビットレート' : Real default 500000.0;
        attribute 'データビットレート' : Real default 2000000.0;
        attribute 'E2E保護あり' : Boolean default false;
    }

    item def 'E2E_CAN_CRC信号' :> 'CAN信号' {
        doc /* CRC-8 SAE J1850、byte0（bbw_can.c:181 送信、bbw_can.c:74 受信照合）。 */
        @SourceTrace { file = "bbw_can.c"; line = 20; symbol = "BBW_Crc8J1850"; }
        :>> '開始ビット' = 0; :>> 'ビット長' = 8; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 255.0; :>> unit = "-";
    }

    port def 'E2E_CANメッセージポート' :> 'CANメッセージポート' {
        doc /*
         * E2E 保護付きメッセージ。byte0 に CRC-8 SAE J1850（多項式 0x1D=29、初期値 0xFF=255、
         * 最終 XOR 0xFF=255）をデータ ID + byte1..7 に対して計算（bbw_can.c:19-44 BBW_Crc8J1850）。
         * byte1 下位 4 bit がローリングカウンタ。
         */
        @SourceTrace { file = "bbw_can.c"; line = 20; symbol = "BBW_Crc8J1850"; }
        attribute :>> 'E2E保護あり' default true;
        attribute 'CRC多項式' : Integer = 29;
        attribute 'CRC初期値' : Integer = 255;
        attribute 'CRC最終XOR' : Integer = 255;
        attribute 'E2EデータID' : Integer default 0;
        attribute 'カウンタビット数' : Integer = 4;
        out item crc : 'E2E_CAN_CRC信号';
    }

    item def 'XBR指令ローリングカウンタ信号' :> 'CAN信号' {
        doc /* byte1 bit0..3 ローリングカウンタ（bbw_can.c:69）。差 1..2 のみ正常（bbw_can.c:78）。 */
        @SourceTrace { file = "bbw_can.c"; line = 69; symbol = "BBW_DecodeXbr"; }
        :>> '開始ビット' = 8; :>> 'ビット長' = 4; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 15.0; :>> unit = "-";
    }
    item def 'XBR指令モード信号' :> 'CAN信号' {
        doc /* byte1 bit4..7 モード BbwXbrMode（bbw_can.c:90）。0..4 が定義値、5..15 も範囲検査なしでそのまま格納される。 */
        @SourceTrace { file = "bbw_can.c"; line = 90; symbol = "BBW_DecodeXbr"; }
        :>> '開始ビット' = 12; :>> 'ビット長' = 4; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 4.0; :>> unit = "enum BbwXbrMode";
    }
    item def 'XBR指令減速度リクエスト信号' :> 'CAN信号' {
        doc /* byte2..3 減速指令 uint16、0.001 m/s^2/bit、オフセット 0（bbw_can.c:84-85）。コードは 7.0 m/s^2 でクランプ（bbw_can.c:86-89）。ヘッダの 0..10 m/s^2 とは相違。 */
        @SourceTrace { file = "bbw_can.c"; line = 85; symbol = "BBW_XBR_DECEL_SCALE"; }
        :>> '開始ビット' = 16; :>> 'ビット長' = 16; :>> factor = 0.001; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 7.0; :>> unit = "m/s^2";
    }
    item def 'XBR指令緊急度信号' :> 'CAN信号' {
        doc /* byte4 bit0..1 緊急度 0..3（bbw_can.c:91、d[4] & 0x03）。状態遷移・減速計算では未使用。 */
        @SourceTrace { file = "bbw_can.c"; line = 91; symbol = "BBW_DecodeXbr"; }
        :>> '開始ビット' = 32; :>> 'ビット長' = 2; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 3.0; :>> unit = "-";
    }
    item def 'XBR指令予約信号' :> 'CAN信号' {
        doc /* byte5..7 予約（0）、bbw_can.h:36。CRC には含まれるが値は検査しない。 */
        @SourceTrace { file = "bbw_can.h"; line = 36; symbol = "XBR_CMD reserved"; }
        :>> '開始ビット' = 40; :>> 'ビット長' = 24; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 0.0; :>> unit = "-";
    }

    port def 'XBR指令ポート' :> 'E2E_CANメッセージポート' {
        doc /*
         * XBR 減速指令（0x110 主系 AD 計算機 / 0x111 冗長系計算機）、受信、DLC 8。
         * bbw_can.h:31-37 のレイアウト、bbw_can.c:66-105 BBW_DecodeXbr の復号。
         * E2E 監視: CRC 不一致、カウンタ差 0（繰り返し）または 2 超（欠落）でエラー。
         * 連続エラー 3 回でチャネル無効、5 周期（50 ms）受信なしでタイムアウト（bbw_can.c:145-148）。
         */
        @SourceTrace { file = "bbw_can.c"; line = 66; symbol = "BBW_DecodeXbr"; }
        attribute 'カウンタ最大差' : Integer = 2;
        attribute '異常上限' : Integer = 3;
        attribute 'タイムアウト周期数' : Integer = 5;
        attribute '指令タイムアウト' : DurationValue = 0.05 [s];
        in item rollingCounter : 'XBR指令ローリングカウンタ信号';
        in item mode : 'XBR指令モード信号';
        in item decelRequest : 'XBR指令減速度リクエスト信号';
        in item urgency : 'XBR指令緊急度信号';
        in item reserved : 'XBR指令予約信号';
    }

    item def '車速車輪速信号' :> 'CAN信号' {
        doc /* byte0..1 車輪速 uint16、1/256 km/h/bit、オフセット 0（bbw_can.c:136-137, bbw_can.h:68）。0.5 km/h 未満で停止判定（bbw_state.c:85）。 */
        @SourceTrace { file = "bbw_can.c"; line = 137; symbol = "BBW_SPEED_SCALE_KPH"; }
        :>> '開始ビット' = 0; :>> 'ビット長' = 16; :>> factor = 0.00390625; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 255.99609375; :>> unit = "km/h";
    }

    port def '車速ポート' :> 'CANメッセージポート' {
        doc /*
         * VEH_SPEED（0x0F0）、シャシーゲートウェイから受信、20 ms、DLC 8。レガシーフレームで
         * CRC もカウンタもなく、タイムアウト監視もない（bbw_can.c:134-137）。最後の値を保持し続ける。
         */
        @SourceTrace { file = "bbw_can.c"; line = 134; symbol = "BBW_ID_VEH_SPEED"; }
        in item wheelSpeed : '車速車輪速信号';
    }

    item def '状態ローリングカウンタ信号' :> 'CAN信号' {
        doc /* byte1 bit0..3 送信カウンタ（bbw_can.c:175-176）。初回送信値は 1。 */
        @SourceTrace { file = "bbw_can.c"; line = 175; symbol = "s_txCounter"; }
        :>> '開始ビット' = 8; :>> 'ビット長' = 4; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 15.0; :>> unit = "-";
    }
    item def '状態動作状態信号' :> 'CAN信号' {
        doc /* byte1 bit4..7 動作モード BbwState 0..5（bbw_can.c:176）。 */
        @SourceTrace { file = "bbw_can.c"; line = 176; symbol = "BBW_StateGet"; }
        :>> '開始ビット' = 12; :>> 'ビット長' = 4; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 5.0; :>> unit = "enum BbwState";
    }
    item def '状態実減速度信号' :> 'CAN信号' {
        doc /* byte2..3 達成減速度 uint16、0.001 m/s^2/bit（bbw_can.c:177）。前軸圧から推定: frontKpa / 0.40 / 120（bbw_state.c:52-57）。クランプなし。 */
        @SourceTrace { file = "bbw_can.c"; line = 177; symbol = "BBW_StateAchievedDecel"; }
        :>> '開始ビット' = 16; :>> 'ビット長' = 16; :>> factor = 0.001; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 65.535; :>> unit = "m/s^2";
    }
    item def '状態前軸圧力信号' :> 'CAN信号' {
        doc /* byte4..5 前軸供給圧 uint16、0.5 kPa/bit（bbw_can.c:178、BBW_KpaToRaw で 0..65535 にクランプ）。 */
        @SourceTrace { file = "bbw_can.c"; line = 178; symbol = "BBW_KpaToRaw"; }
        :>> '開始ビット' = 32; :>> 'ビット長' = 16; :>> factor = 0.5; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 32767.5; :>> unit = "kPa";
    }
    item def '状態故障概要信号' :> 'CAN信号' {
        doc /* byte6 故障サマリ（bbw_diag.c:161-171）: bit0 主系喪失（タイムアウトまたは E2E）、bit1 冗長系喪失、bit2 モジュレータ（前・後・トレーラ）、bit3 電源（A または B）、bit4 反応時間超過。 */
        @SourceTrace { file = "bbw_diag.c"; line = 161; symbol = "BBW_DiagFaultSummary"; }
        :>> '開始ビット' = 48; :>> 'ビット長' = 8; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 31.0; :>> unit = "bitmask";
    }
    item def '状態発生中DTC数信号' :> 'CAN信号' {
        doc /* byte7 アクティブ DTC 数 0..12（bbw_can.c:180、bbw_diag.c:150）。 */
        @SourceTrace { file = "bbw_can.c"; line = 180; symbol = "BBW_DiagActiveCount"; }
        :>> '開始ビット' = 56; :>> 'ビット長' = 8; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 12.0; :>> unit = "-";
    }

    port def '状態ポート' :> 'E2E_CANメッセージポート' {
        doc /*
         * STATUS（0x210）、送信、10 ms（毎高速タスク、bbw_main.c:44）、DLC 8。
         * E2E: データ ID 0x61、送信カウンタは送信前にインクリメント（bbw_can.c:168-183 BBW_CanTxStatus）。
         */
        @SourceTrace { file = "bbw_can.c"; line = 168; symbol = "BBW_CanTxStatus"; }
        out item rollingCounter : '状態ローリングカウンタ信号';
        out item operatingState : '状態動作状態信号';
        out item achievedDecel : '状態実減速度信号';
        out item frontPressure : '状態前軸圧力信号';
        out item faultSummary : '状態故障概要信号';
        out item '発生中DTC数' : '状態発生中DTC数信号';
    }

    item def '圧力前軸圧力信号' :> 'CAN信号' {
        doc /* byte0..1 前軸供給圧 uint16、0.5 kPa/bit（bbw_can.c:192）。 */
        @SourceTrace { file = "bbw_can.c"; line = 192; symbol = "BBW_CanTxPressure"; }
        :>> '開始ビット' = 0; :>> 'ビット長' = 16; :>> factor = 0.5; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 32767.5; :>> unit = "kPa";
    }
    item def '圧力後軸圧力信号' :> 'CAN信号' {
        doc /* byte2..3 後軸供給圧 uint16、0.5 kPa/bit（bbw_can.c:193）。 */
        @SourceTrace { file = "bbw_can.c"; line = 193; symbol = "BBW_CanTxPressure"; }
        :>> '開始ビット' = 16; :>> 'ビット長' = 16; :>> factor = 0.5; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 32767.5; :>> unit = "kPa";
    }
    item def '圧力トレーラ圧力信号' :> 'CAN信号' {
        doc /* byte4..5 トレーラ制御ライン圧 uint16、0.5 kPa/bit（bbw_can.c:194）。 */
        @SourceTrace { file = "bbw_can.c"; line = 194; symbol = "BBW_CanTxPressure"; }
        :>> '開始ビット' = 32; :>> 'ビット長' = 16; :>> factor = 0.5; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 32767.5; :>> unit = "kPa";
    }
    item def '圧力供給圧信号' :> 'CAN信号' {
        doc /* byte6..7 リザーバ供給圧 uint16、0.5 kPa/bit（bbw_can.c:195）。 */
        @SourceTrace { file = "bbw_can.c"; line = 195; symbol = "BBW_CanTxPressure"; }
        :>> '開始ビット' = 48; :>> 'ビット長' = 16; :>> factor = 0.5; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 32767.5; :>> unit = "kPa";
    }

    port def '圧力ポート' :> 'CANメッセージポート' {
        doc /*
         * PRESSURE（0x211）、送信、20 ms（s_tick 偶数時、bbw_main.c:45-48）、DLC 8。
         * 診断用で E2E 保護なし（bbw_can.h:60, bbw_can.c:185-197 BBW_CanTxPressure）。
         */
        @SourceTrace { file = "bbw_can.c"; line = 185; symbol = "BBW_CanTxPressure"; }
        out item frontPressure : '圧力前軸圧力信号';
        out item rearPressure : '圧力後軸圧力信号';
        out item trailerPressure : '圧力トレーラ圧力信号';
        out item supplyPressure : '圧力供給圧信号';
    }

    item def 'DM1発生中DTC数信号' :> 'CAN信号' {
        doc /* byte0 アクティブ DTC 数（bbw_can.c:207）。J1939 のランプ状態ではない。 */
        @SourceTrace { file = "bbw_can.c"; line = 207; symbol = "BBW_CanTxDm1"; }
        :>> '開始ビット' = 0; :>> 'ビット長' = 8; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 12.0; :>> unit = "-";
    }
    item def 'DM1_SPN下位信号' :> 'CAN信号' {
        doc /* byte1..2 SPN 下位 16 bit（bbw_can.c:209-210）。 */
        @SourceTrace { file = "bbw_can.c"; line = 209; symbol = "BBW_CanTxDm1"; }
        :>> '開始ビット' = 8; :>> 'ビット長' = 16; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 65535.0; :>> unit = "-";
    }
    item def 'DM1_FMI信号' :> 'CAN信号' {
        doc /* byte3 bit0..4 FMI（bbw_can.c:211）。 */
        @SourceTrace { file = "bbw_can.c"; line = 211; symbol = "BBW_CanTxDm1"; }
        :>> '開始ビット' = 24; :>> 'ビット長' = 5; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 31.0; :>> unit = "-";
    }
    item def 'DM1_SPN上位信号' :> 'CAN信号' {
        doc /* byte3 bit5..7 SPN 上位 3 bit（bbw_can.c:211）。 */
        @SourceTrace { file = "bbw_can.c"; line = 211; symbol = "BBW_CanTxDm1"; }
        :>> '開始ビット' = 29; :>> 'ビット長' = 3; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 0.0; :>> '最大値' = 7.0; :>> unit = "-";
    }
    item def 'DM1フィラ信号' :> 'CAN信号' {
        doc /* byte4..7 0xFF 固定（bbw_can.c:212-215）。発生回数（OC）は送らない。 */
        @SourceTrace { file = "bbw_can.c"; line = 212; symbol = "BBW_CanTxDm1"; }
        :>> '開始ビット' = 32; :>> 'ビット長' = 32; :>> factor = 1.0; :>> offset = 0.0; :>> '最小値' = 4294967295.0; :>> '最大値' = 4294967295.0; :>> unit = "-";
    }

    port def 'DM1ポート' :> 'CANメッセージポート' {
        doc /*
         * DM1（0x3A0）、送信、1000 ms（低速タスク内で s_tick % 100 == 0、bbw_main.c:51-57）、DLC 8、
         * E2E 保護なし。先頭のアクティブ DTC 1 件だけを送る（bbw_can.c:199-217 BBW_CanTxDm1）。
         * J1939 標準 DM1（29 bit、PGN 65226、byte0..1 ランプ状態）とは形式が異なる。
         */
        @SourceTrace { file = "bbw_can.c"; line = 199; symbol = "BBW_CanTxDm1"; }
        out item '発生中DTC数' : 'DM1発生中DTC数信号';
        out item spnLow : 'DM1_SPN下位信号';
        out item 'FMI' : 'DM1_FMI信号';
        out item spnHigh : 'DM1_SPN上位信号';
        out item filler : 'DM1フィラ信号';
    }

    /* ------------------------------------------------------------ */
    /* Diagnostics                                                   */
    /* ------------------------------------------------------------ */

    item def '故障コード' {
        doc /*
         * J1939 SPN/FMI 形式の DTC（独自 SPN 範囲、bbw_diag.h:6）。デバウンスはカウンタ式:
         * 3 回連続の失敗報告でセット、50 回連続の合格報告で解除（bbw_diag.c:14-15, 61-75）。
         * critical は k_dtcTable の critical フラグ（bbw_diag.c:21）、criticalWith は
         * 2 件同時アクティブで FAULT を強制する相手の DTC（bbw_diag.c:145-146）。
         */
        @SourceTrace { file = "bbw_diag.c"; line = 17; symbol = "BbwDtcInfo_t"; }
        attribute 'SPN' : Integer;
        attribute 'FMI' : Integer;
        attribute critical : Boolean;
        attribute '重大故障条件' : String;
        attribute '設定元' : String;
        attribute '異常判定回数' : Integer = 3;
        attribute '正常判定回数' : Integer = 50;
    }

    /* ------------------------------------------------------------ */
    /* Operating mode state machine                                  */
    /* ------------------------------------------------------------ */

    state def 'BBW運転モード' {
        doc /*
         * 動作モードマネージャ（bbw_state.c:80-204 BBW_StateStep、10 ms 周期）。
         * 評価順: まず全体条件として FAULT 以外の状態で BBW_DiagCritical() が真なら FAULT へ
         * （bbw_state.c:88-91）、次に現在状態の if/else if 連鎖。ガードには else if の
         * 優先順位を否定項として含め、コードと同じく排他的にしてある。
         * FAULT は電源再投入までラッチ（出口なし、bbw_state.c:197-202）。
         * ガードが参照する属性は C の入力に対応: priValid/secValid = g_bbwRx.*.valid、
         * priMode/secMode = g_bbwRx.*.mode、standstill = speedKph < 0.5、
         * frontModOk/rearModOk/parkApplied = HAL_GetSensors()、diagCritical = BBW_DiagCritical()、
         * activeDtcCount = BBW_DiagActiveCount()、recoveryCycles = s_recoveryCycles、
         * standstillTime = s_standstillMs。
         */
        @SourceTrace { file = "bbw_state.c"; line = 80; symbol = "BBW_StateStep"; }
        attribute '自己診断正常' : Boolean default true;
        attribute 'ウォッチドッグリセット発生' : Boolean default false;
        attribute '診断重大故障' : Boolean default false;
        attribute '主系有効' : Boolean default false;
        attribute '副系有効' : Boolean default false;
        attribute '主系モード' : Integer default 0;
        attribute '副系モード' : Integer default 0;
        attribute 'XBR係合モード' : Integer = 1;
        attribute 'XBR解除モード' : Integer = 3;
        attribute 'XBR_MRCモード' : Integer = 4;
        attribute '発生中DTC数' : Integer default 0;
        attribute '停止中' : Boolean default true;
        attribute '前軸モジュレータ正常' : Boolean default true;
        attribute '後軸モジュレータ正常' : Boolean default true;
        attribute '駐車ブレーキ作動中' : Boolean default false;
        attribute '復帰周期数' : Integer default 0;
        attribute '復帰周期数上限' : Integer = 100;
        attribute '停止判定時間' : DurationValue default 0 [s];
        attribute '停止保持' : DurationValue = 3 [s];
        attribute '駐車ブレーキ指令' : Boolean default false;

        entry; then '初期化';

        state '初期化' {
            doc /* 初期状態（bbw_state.c:41, 95-106）。減速指令 0。HAL_SelfTest() と HAL_WdgWasReset() を 1 周期で判定。 */
            @SourceTrace { file = "bbw_state.c"; line = 95; symbol = "BBW_ST_INIT"; }
        }
        state '待機' {
            doc /* 待機（bbw_state.c:108-116）。減速指令 0、ドライバとパーキングブレーキのみ。 */
            @SourceTrace { file = "bbw_state.c"; line = 108; symbol = "BBW_ST_STANDBY"; }
        }
        state '自動運転中' {
            doc /* 自動運転制動（bbw_state.c:118-141）。減速指令 = max(主系, 冗長系)（bbw_state.c:120）。 */
            @SourceTrace { file = "bbw_state.c"; line = 118; symbol = "BBW_ST_AUTONOMOUS_ACTIVE"; }
        }
        state '片系縮退' {
            doc /* 縮退（bbw_state.c:143-171）。有効な方のチャネル（主系優先）の指令をそのまま使う（bbw_state.c:145）。最大 60 s。 */
            @SourceTrace { file = "bbw_state.c"; line = 143; symbol = "BBW_ST_DEGRADED_SINGLE_CHANNEL"; }
        }
        state 'MRC停止' {
            doc /* 最小リスク停止（bbw_state.c:173-195）。入場時の指令から 2.5 m/s^3 で 3.0 m/s^2 へランプ（bbw_state.c:34, 62-78）、有効チャネルはそれ以上の指令のみ可（max 選択）。 */
            @SourceTrace { file = "bbw_state.c"; line = 173; symbol = "BBW_ST_MRC_STOP"; }
        }
        state '故障' {
            doc /* 故障（bbw_state.c:197-202）。サービスブレーキを排気し減速指令 0、パーキング（スプリング）ブレーキを毎周期指令。電源再投入までラッチ。 */
            @SourceTrace { file = "bbw_state.c"; line = 197; symbol = "BBW_ST_FAULT"; }
            entry assign '駐車ブレーキ指令' := true;
        }

        transition '初期化から待機へ' first '初期化'
            if not '診断重大故障' and '自己診断正常' and not 'ウォッチドッグリセット発生' then '待機' {
            doc /* bbw_state.c:97-99。HAL_SelfTest() 合格かつ HAL_WdgWasReset() 偽。 */
            @SourceTrace { file = "bbw_state.c"; line = 97; symbol = "HAL_SelfTest"; }
        }
        transition '初期化から故障へ' first '初期化'
            if not '診断重大故障' and (not '自己診断正常' or 'ウォッチドッグリセット発生') then '故障' {
            doc /* bbw_state.c:101-104。else 分岐。BBW_DTC_WDG_RESET を 1 回だけ報告して FAULT へ（相違 D4）。 */
            @SourceTrace { file = "bbw_state.c"; line = 104; symbol = "BBW_Enter"; }
        }
        transition '待機から自動運転中へ' first '待機'
            if not '診断重大故障' and '主系有効' and '副系有効' and '主系モード' == 'XBR係合モード' and '発生中DTC数' == 0 then '自動運転中' {
            doc /* bbw_state.c:110-114。両チャネル有効、主系モード ENGAGE（冗長系のモードは見ない）、アクティブ DTC 数 0。 */
            @SourceTrace { file = "bbw_state.c"; line = 111; symbol = "BBW_XBR_MODE_ENGAGE"; }
        }
        transition '自動運転中から待機へ' first '自動運転中'
            if not '診断重大故障' and '主系モード' == 'XBR解除モード' and '停止中' then '待機' {
            doc /* bbw_state.c:121-123。主系モード DISENGAGE かつ停止（< 0.5 km/h）。最優先の分岐。 */
            @SourceTrace { file = "bbw_state.c"; line = 121; symbol = "BBW_XBR_MODE_DISENGAGE"; }
        }
        transition '自動運転中から両系喪失でMRCへ' first '自動運転中'
            if not '診断重大故障' and not ('主系モード' == 'XBR解除モード' and '停止中') and not '主系有効' and not '副系有効' then 'MRC停止' {
            doc /* bbw_state.c:125-127。両チャネル無効。 */
            @SourceTrace { file = "bbw_state.c"; line = 125; symbol = "BBW_StateStep"; }
        }
        transition '自動運転中からMRCリクエストでMRCへ' first '自動運転中'
            if not '診断重大故障' and not ('主系モード' == 'XBR解除モード' and '停止中') and ('主系有効' or '副系有効') and ('主系モード' == 'XBR_MRCモード' or '副系モード' == 'XBR_MRCモード') then 'MRC停止' {
            doc /* bbw_state.c:129-131。どちらかのチャネルが MRC を指令。有効性は問わない（無効チャネルは最後の正常値のモード）。 */
            @SourceTrace { file = "bbw_state.c"; line = 129; symbol = "BBW_XBR_MODE_MRC"; }
        }
        transition '自動運転中から縮退へ' first '自動運転中'
            if not '診断重大故障' and not ('主系モード' == 'XBR解除モード' and '停止中') and ('主系有効' or '副系有効') and not ('主系モード' == 'XBR_MRCモード' or '副系モード' == 'XBR_MRCモード') and (not '主系有効' or not '副系有効' or not '前軸モジュレータ正常' or not '後軸モジュレータ正常') then '片系縮退' {
            doc /* bbw_state.c:133-135。片チャネル無効、または前軸・後軸モジュレータのどちらかが異常（相違 D8）。 */
            @SourceTrace { file = "bbw_state.c"; line = 133; symbol = "BBW_StateStep"; }
        }
        transition '縮退から両系喪失でMRCへ' first '片系縮退'
            if not '診断重大故障' and not '主系有効' and not '副系有効' then 'MRC停止' {
            doc /* bbw_state.c:146-148。両チャネル無効。 */
            @SourceTrace { file = "bbw_state.c"; line = 146; symbol = "BBW_StateStep"; }
        }
        transition '縮退から時間超過でMRCへ' first '片系縮退'
            accept after 60 [s] if not '診断重大故障' and ('主系有効' or '副系有効') then 'MRC停止' {
            doc /* bbw_state.c:150-152。s_degradedMs >= BBW_DEGRADED_MAX_MS（60000 ms）。s_degradedMs は入場時に 0 クリア（bbw_state.c:29）され毎周期 10 ms 加算（bbw_state.c:144）。この時刻以降は下位の分岐より優先。 */
            @SourceTrace { file = "bbw_state.c"; line = 150; symbol = "BBW_DEGRADED_MAX_MS"; }
        }
        transition '縮退から待機へ' first '片系縮退'
            if not '診断重大故障' and ('主系有効' or '副系有効') and '主系モード' == 'XBR解除モード' and '停止中' then '待機' {
            doc /* bbw_state.c:154-158。field fix FR-2291: ヤードでの MRC なしのディスエンゲージ。主系モード DISENGAGE かつ停止。60 s 経過前のみ。 */
            @SourceTrace { file = "bbw_state.c"; line = 154; symbol = "BBW_XBR_MODE_DISENGAGE"; }
        }
        transition '縮退から自動運転中へ' first '片系縮退'
            if not '診断重大故障' and '主系有効' and '副系有効' and '前軸モジュレータ正常' and '後軸モジュレータ正常' and not ('主系モード' == 'XBR解除モード' and '停止中') and '復帰周期数' >= '復帰周期数上限' then '自動運転中' {
            doc /* bbw_state.c:159-165。両チャネル有効かつ両モジュレータ正常が 100 周期（1 s）連続。条件が崩れるとカウンタは 0 に戻る（bbw_state.c:169）。60 s 経過前のみ。 */
            @SourceTrace { file = "bbw_state.c"; line = 162; symbol = "BBW_RECOVERY_CYCLES"; }
        }
        transition 'MRCから待機へ' first 'MRC停止'
            if not '診断重大故障' and '停止中' and '停止判定時間' >= '停止保持' and '駐車ブレーキ作動中' then '待機' {
            doc /* bbw_state.c:179-188。停止が 3 s 連続（停止でなくなると 0 に戻る、bbw_state.c:193）、HAL_ParkBrake(true) を指令し、parkApplied を確認して STANDBY へ。 */
            @SourceTrace { file = "bbw_state.c"; line = 182; symbol = "BBW_STANDSTILL_HOLD_MS"; }
        }
        transition '初期化から重大故障へ' first '初期化' if '診断重大故障' then '故障' {
            doc /* bbw_state.c:88-91。全体条件: FAULT 以外で BBW_DiagCritical() 真。switch より先に評価される。 */
            @SourceTrace { file = "bbw_state.c"; line = 88; symbol = "BBW_DiagCritical"; }
        }
        transition '待機から重大故障へ' first '待機' if '診断重大故障' then '故障' {
            doc /* bbw_state.c:88-91。全体条件の critical 故障。 */
            @SourceTrace { file = "bbw_state.c"; line = 88; symbol = "BBW_DiagCritical"; }
        }
        transition '自動運転中から重大故障へ' first '自動運転中' if '診断重大故障' then '故障' {
            doc /* bbw_state.c:88-91。全体条件の critical 故障。 */
            @SourceTrace { file = "bbw_state.c"; line = 88; symbol = "BBW_DiagCritical"; }
        }
        transition '縮退から重大故障へ' first '片系縮退' if '診断重大故障' then '故障' {
            doc /* bbw_state.c:88-91。全体条件の critical 故障。 */
            @SourceTrace { file = "bbw_state.c"; line = 88; symbol = "BBW_DiagCritical"; }
        }
        transition 'MRCから重大故障へ' first 'MRC停止' if '診断重大故障' then '故障' {
            doc /* bbw_state.c:88-91。全体条件の critical 故障。 */
            @SourceTrace { file = "bbw_state.c"; line = 88; symbol = "BBW_DiagCritical"; }
        }
    }

    /* ------------------------------------------------------------ */
    /* ECU software                                                  */
    /* ------------------------------------------------------------ */

    part def 'BBW_ECUソフトウェア' {
        doc /*
         * BBW-24 ECU ソフトウェア（ベアメタルのサイクリックエグゼクティブ、RTOS なし、bbw_main.c:59-77）。
         * 10 ms 高速タスクの実行順: CAN 受信 → 診断 → 動作モード → アクチュエーション → STATUS 送信
         * → 20 ms ごとに PRESSURE 送信（bbw_main.c:38-49）。低速タスク（100 ms）は DM1 送信のみ。
         * 毎周期の最後にウォッチドッグを処理（bbw_main.c:74）。
         * アクチュエーション: 圧力 = 減速指令 x 120 kPa/(m/s^2)、850 kPa で制限、前軸 40 %、後軸 60 %、
         * トレーラ = 後軸 x 1.0、片軸モジュレータ喪失時は健全側に全量（bbw_main.c:19-36）。
         */
        @SourceTrace { file = "bbw_main.c"; line = 59; symbol = "main"; }

        // ---- scheduling (bbw_cfg.h:22-24, bbw_main.c:45-56)
        attribute 'タスク周期' : DurationValue = 0.01 [s] {
            doc /* 高速タスク周期 10 ms（bbw_cfg.h:22 BBW_TASK_PERIOD_MS）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 22; symbol = "BBW_TASK_PERIOD_MS"; }
        }
        attribute '低速タスク周期' : DurationValue = 0.1 [s] {
            doc /* 低速タスク周期 = 10 x 高速 = 100 ms（bbw_cfg.h:23 BBW_SLOW_TASK_DIV、bbw_main.c:70）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 23; symbol = "BBW_SLOW_TASK_DIV"; }
        }
        attribute 'DM1周期' : DurationValue = 1 [s] {
            doc /* DM1 送信周期 1000 ms（bbw_cfg.h:24 BBW_DM1_PERIOD_MS、bbw_main.c:53）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 24; symbol = "BBW_DM1_PERIOD_MS"; }
        }
        // ---- watchdog (bbw_cfg.h:27-28)
        attribute 'ウォッチドッグ時間' : DurationValue = 0.03 [s] {
            doc /* 外部ウィンドウウォッチドッグのタイムアウト 30 ms（bbw_cfg.h:27 BBW_WDG_TIMEOUT_MS）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 27; symbol = "BBW_WDG_TIMEOUT_MS"; }
        }
        attribute 'ウォッチドッグ窓開' : DurationValue = 0.005 [s] {
            doc /* ウィンドウ開始 5 ms、これより早い処理は不正（bbw_cfg.h:28 BBW_WDG_WINDOW_OPEN_MS）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 28; symbol = "BBW_WDG_WINDOW_OPEN_MS"; }
        }
        attribute 'ウォッチドッグ処理周期' : DurationValue = 0.01 [s] {
            doc /* ウォッチドッグ処理はメインループ 1 周につき 1 回 = 10 ms（bbw_main.c:74 HAL_WdgService）。 */
            @SourceTrace { file = "bbw_main.c"; line = 74; symbol = "HAL_WdgService"; }
        }
        // ---- command supervision (bbw_cfg.h:31-34)
        attribute '指令タイムアウト周期数' : Integer = 5 {
            doc /* 受信なし 5 周期でタイムアウト（bbw_cfg.h:31 BBW_CMD_TIMEOUT_CYCLES、bbw_can.c:145-148）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 31; symbol = "BBW_CMD_TIMEOUT_CYCLES"; }
        }
        attribute '指令タイムアウト時間' : DurationValue = 0.05 [s] {
            doc /* 指令タイムアウト 5 x 10 ms = 50 ms。ヘッダ bbw_can.h:10 の 40 ms はコードと不一致。 */
            @SourceTrace { file = "bbw_can.c"; line = 145; symbol = "BBW_CMD_TIMEOUT_CYCLES"; }
        }
        attribute 'E2Eカウンタ最大差' : Integer = 2 {
            doc /* カウンタ差の許容最大値 2（bbw_cfg.h:32 BBW_E2E_MAX_DELTA）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 32; symbol = "BBW_E2E_MAX_DELTA"; }
        }
        attribute 'E2E異常上限' : Integer = 3 {
            doc /* 連続 E2E エラー 3 回でチャネル無効（bbw_cfg.h:33 BBW_E2E_ERR_LIMIT）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 33; symbol = "BBW_E2E_ERR_LIMIT"; }
        }
        attribute '復帰周期数' : Integer = 100 {
            doc /* 縮退からの復帰に必要な連続健全周期数 100（bbw_cfg.h:34 BBW_RECOVERY_CYCLES）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 34; symbol = "BBW_RECOVERY_CYCLES"; }
        }
        attribute '復帰時間' : DurationValue = 1 [s] {
            doc /* 復帰時間 100 x 10 ms = 1 s（bbw_cfg.h:34, bbw_state.c:162）。 */
            @SourceTrace { file = "bbw_state.c"; line = 162; symbol = "BBW_RECOVERY_CYCLES"; }
        }
        attribute '指令系統数' : Integer = 2 {
            doc /* XBR 指令チャネル数 2（主系 0x110、冗長系 0x111、bbw_can.h:83-84 BbwCanRx_t）。 */
            @SourceTrace { file = "bbw_can.h"; line = 83; symbol = "BbwCanRx_t.pri"; }
        }
        // ---- reaction monitor (bbw_cfg.h:37-39)
        attribute '反応時間配分' : DurationValue = 0.2 [s] {
            doc /* 反応時間予算 200 ms（bbw_cfg.h:37 BBW_REACTION_BUDGET_MS）。監視は内部減速指令 >= 0.5 m/s^2 から後軸圧 >= 50 kPa まで（bbw_diag.c:80-113）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 37; symbol = "BBW_REACTION_BUDGET_MS"; }
        }
        attribute '反応立上り圧' : PressureValue = 50000 [Pa] {
            doc /* 圧力立ち上がり判定 50 kPa（bbw_cfg.h:38 BBW_REACTION_RISE_KPA）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 38; symbol = "BBW_REACTION_RISE_KPA"; }
        }
        attribute '反応最小リクエスト' : AccelerationValue = 0.5 [m/s^2] {
            doc /* 監視対象とする最小減速指令 0.5 m/s^2（bbw_cfg.h:39 BBW_REACTION_REQ_MIN_MPS2）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 39; symbol = "BBW_REACTION_REQ_MIN_MPS2"; }
        }
        // ---- deceleration and pressure (bbw_cfg.h:42-46)
        attribute '最大減速度' : AccelerationValue = 7.0 [m/s^2] {
            doc /* 減速指令の上限 7.0 m/s^2（bbw_cfg.h:42 BBW_MAX_DECEL_MPS2、bbw_can.c:86）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 42; symbol = "BBW_MAX_DECEL_MPS2"; }
        }
        attribute '圧力ゲインkPa毎ms2' : Real = 120.0 {
            doc /* 静的ゲイン 120 kPa/(m/s^2)、積載車両（bbw_cfg.h:43 BBW_KPA_PER_MPS2）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 43; symbol = "BBW_KPA_PER_MPS2"; }
        }
        attribute '最大圧力' : PressureValue = 850000 [Pa] {
            doc /* 指令圧上限 850 kPa（bbw_cfg.h:44 BBW_MAX_PRESSURE_KPA、bbw_main.c:26）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 44; symbol = "BBW_MAX_PRESSURE_KPA"; }
        }
        attribute '前軸配分' : Real = 0.4 {
            doc /* 前軸配分 40 %（bbw_cfg.h:45 BBW_FRONT_SHARE）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 45; symbol = "BBW_FRONT_SHARE"; }
        }
        attribute 'トレーラ配分' : Real = 1.0 {
            doc /* トレーラ制御ライン = 後軸圧 x 1.0（bbw_cfg.h:46 BBW_TRAILER_SHARE）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 46; symbol = "BBW_TRAILER_SHARE"; }
        }
        // ---- minimal risk condition (bbw_cfg.h:49-53)
        attribute 'MRC減速度' : AccelerationValue = 3.0 [m/s^2] {
            doc /* MRC 目標減速度 3.0 m/s^2（bbw_cfg.h:49 BBW_MRC_DECEL_MPS2）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 49; symbol = "BBW_MRC_DECEL_MPS2"; }
        }
        attribute 'MRC躍度' : Real = 2.5 {
            doc /* MRC ランプ率（ジャーク）2.5 m/s^3、1 周期 0.025 m/s^2（bbw_cfg.h:50 BBW_MRC_JERK_MPS3、bbw_state.c:64）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 50; symbol = "BBW_MRC_JERK_MPS3"; }
        }
        attribute '縮退最大時間' : DurationValue = 60 [s] {
            doc /* 単一チャネル運転の上限 60 s（bbw_cfg.h:51 BBW_DEGRADED_MAX_MS、bbw_state.c:150）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 51; symbol = "BBW_DEGRADED_MAX_MS"; }
        }
        attribute '停止判定速度kmh' : Real = 0.5 {
            doc /* 停止判定 0.5 km/h 未満（bbw_cfg.h:52 BBW_STANDSTILL_KPH、bbw_state.c:85）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 52; symbol = "BBW_STANDSTILL_KPH"; }
        }
        attribute '停止保持' : DurationValue = 3 [s] {
            doc /* パーキングブレーキへ引き渡す前の停止保持 3 s（bbw_cfg.h:53 BBW_STANDSTILL_HOLD_MS、bbw_state.c:182）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 53; symbol = "BBW_STANDSTILL_HOLD_MS"; }
        }
        // ---- supply and plausibility (bbw_cfg.h:56-60)
        attribute '供給下限' : ElectricPotentialValue = 18 [V] {
            doc /* 24 V ネット A/B の下限 18 V（bbw_cfg.h:56 BBW_SUPPLY_MIN_MV）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 56; symbol = "BBW_SUPPLY_MIN_MV"; }
        }
        attribute '供給上限' : ElectricPotentialValue = 32 [V] {
            doc /* 24 V ネット A/B の上限 32 V（bbw_cfg.h:57 BBW_SUPPLY_MAX_MV）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 57; symbol = "BBW_SUPPLY_MAX_MV"; }
        }
        attribute '圧力妥当性' : PressureValue = 80000 [Pa] {
            doc /* 冗長圧力センサの不一致しきい値 80 kPa（bbw_cfg.h:60 BBW_PRESS_PLAUS_KPA）。 */
            @SourceTrace { file = "bbw_cfg.h"; line = 60; symbol = "BBW_PRESS_PLAUS_KPA"; }
        }
        // ---- DTC debounce (bbw_diag.c:14-15)
        attribute 'DTC確定時間' : DurationValue = 0.03 [s] {
            doc /* DTC セット: 3 回連続失敗 = 毎周期報告で 30 ms（bbw_diag.c:14 DEB_FAIL）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 14; symbol = "DEB_FAIL"; }
        }
        attribute 'DTC回復時間' : DurationValue = 0.5 [s] {
            doc /* DTC 解除: 50 回連続合格 = 毎周期報告で 500 ms（bbw_diag.c:15 DEB_PASS）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 15; symbol = "DEB_PASS"; }
        }

        // ---- CAN ports, one per message
        port '主系XBR指令' : 'XBR指令ポート' {
            doc /* 受信 XBR_CMD_PRI 0x110（272）、主系 AD 計算機、10 ms、E2E データ ID 0x51（81）。bbw_can.h:19, 27。 */
            @SourceTrace { file = "bbw_can.h"; line = 19; symbol = "BBW_ID_XBR_CMD_PRI"; }
            :>> 'CAN_ID' = 272;
            :>> '周期' = 0.01 [s];
            :>> 'E2EデータID' = 81;
        }
        port '副系XBR指令' : 'XBR指令ポート' {
            doc /* 受信 XBR_CMD_SEC 0x111（273）、冗長系計算機、10 ms、E2E データ ID 0x52（82）。bbw_can.h:20, 28。 */
            @SourceTrace { file = "bbw_can.h"; line = 20; symbol = "BBW_ID_XBR_CMD_SEC"; }
            :>> 'CAN_ID' = 273;
            :>> '周期' = 0.01 [s];
            :>> 'E2EデータID' = 82;
        }
        port '車速' : '車速ポート' {
            doc /* 受信 VEH_SPEED 0x0F0（240）、シャシーゲートウェイ、20 ms、保護なし。bbw_can.h:21。 */
            @SourceTrace { file = "bbw_can.h"; line = 21; symbol = "BBW_ID_VEH_SPEED"; }
            :>> 'CAN_ID' = 240;
            :>> '周期' = 0.02 [s];
        }
        port status : '状態ポート' {
            doc /* 送信 STATUS 0x210（528）、10 ms、E2E データ ID 0x61（97）。bbw_can.h:22, 29。 */
            @SourceTrace { file = "bbw_can.h"; line = 22; symbol = "BBW_ID_STATUS"; }
            :>> 'CAN_ID' = 528;
            :>> '周期' = 0.01 [s];
            :>> 'E2EデータID' = 97;
        }
        port pressure : '圧力ポート' {
            doc /* 送信 PRESSURE 0x211（529）、20 ms、保護なし（診断用）。bbw_can.h:23, bbw_main.c:45-48。 */
            @SourceTrace { file = "bbw_can.h"; line = 23; symbol = "BBW_ID_PRESSURE"; }
            :>> 'CAN_ID' = 529;
            :>> '周期' = 0.02 [s];
        }
        port 'DM1' : 'DM1ポート' {
            doc /* 送信 DM1 0x3A0（928）、1000 ms、保護なし。bbw_can.h:24, bbw_main.c:53-56。 */
            @SourceTrace { file = "bbw_can.h"; line = 24; symbol = "BBW_ID_DM1"; }
            :>> 'CAN_ID' = 928;
            :>> '周期' = 1 [s];
        }

        // ---- DTCs (bbw_diag.h:14-29, bbw_diag.c:24-38)
        item 'DTC主系タイムアウト' : '故障コード' {
            doc /* SPN 520400 FMI 9。主系 XBR の ageCycles >= 5（bbw_can.c:150）。毎周期報告。 */
            @SourceTrace { file = "bbw_diag.c"; line = 26; symbol = "BBW_DTC_PRI_TIMEOUT"; }
            :>> 'SPN' = 520400; :>> 'FMI' = 9; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_can.c:150 pri.ageCycles >= BBW_CMD_TIMEOUT_CYCLES";
        }
        item 'DTC副系タイムアウト' : '故障コード' {
            doc /* SPN 520401 FMI 9。冗長系 XBR の ageCycles >= 5（bbw_can.c:151）。毎周期報告。 */
            @SourceTrace { file = "bbw_diag.c"; line = 27; symbol = "BBW_DTC_SEC_TIMEOUT"; }
            :>> 'SPN' = 520401; :>> 'FMI' = 9; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_can.c:151 sec.ageCycles >= BBW_CMD_TIMEOUT_CYCLES";
        }
        item 'DTC主系E2E' : '故障コード' {
            doc /* SPN 520402 FMI 19。主系の E2E 不良フレーム受信時のみ報告、失敗 = e2eErrCnt >= 3（bbw_can.c:121-125）。正常フレームでは合格報告しない。 */
            @SourceTrace { file = "bbw_diag.c"; line = 28; symbol = "BBW_DTC_PRI_E2E"; }
            :>> 'SPN' = 520402; :>> 'FMI' = 19; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_can.c:123 bad frame with pri.e2eErrCnt >= BBW_E2E_ERR_LIMIT";
        }
        item 'DTC副系E2E' : '故障コード' {
            doc /* SPN 520403 FMI 19。冗長系の E2E 不良フレーム受信時のみ報告（bbw_can.c:128-132）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 29; symbol = "BBW_DTC_SEC_E2E"; }
            :>> 'SPN' = 520403; :>> 'FMI' = 19; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_can.c:130 bad frame with sec.e2eErrCnt >= BBW_E2E_ERR_LIMIT";
        }
        item 'DTC前軸モジュレータ' : '故障コード' {
            doc /* SPN 520410 FMI 5。前軸モジュレータのコイル・フィードバック異常 !frontModOk（bbw_diag.c:119）。後軸と同時で FAULT（bbw_diag.c:145）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 30; symbol = "BBW_DTC_FRONT_MOD"; }
            :>> 'SPN' = 520410; :>> 'FMI' = 5; :>> critical = false; :>> '重大故障条件' = "BBW_DTC_REAR_MOD";
            :>> '設定元' = "bbw_diag.c:119 !frontModOk";
        }
        item 'DTC後軸モジュレータ' : '故障コード' {
            doc /* SPN 520411 FMI 5。後軸モジュレータ異常 !rearModOk（bbw_diag.c:120）。前軸と同時で FAULT（bbw_diag.c:145）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 31; symbol = "BBW_DTC_REAR_MOD"; }
            :>> 'SPN' = 520411; :>> 'FMI' = 5; :>> critical = false; :>> '重大故障条件' = "BBW_DTC_FRONT_MOD";
            :>> '設定元' = "bbw_diag.c:120 !rearModOk";
        }
        item 'DTCトレーラモジュレータ' : '故障コード' {
            doc /* SPN 520412 FMI 5。トレーラ制御モジュール異常 !trailerModOk（bbw_diag.c:121）。モード遷移には直接影響しない（エンゲージ禁止のみ）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 32; symbol = "BBW_DTC_TRAILER_MOD"; }
            :>> 'SPN' = 520412; :>> 'FMI' = 5; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_diag.c:121 !trailerModOk";
        }
        item 'DTC圧力妥当性' : '故障コード' {
            doc /* SPN 520420 FMI 2。前軸または後軸の冗長センサ差 > 80 kPa（bbw_diag.c:123-125）。トレーラ圧と供給圧は検査しない。 */
            @SourceTrace { file = "bbw_diag.c"; line = 33; symbol = "BBW_DTC_PRESS_PLAUS"; }
            :>> 'SPN' = 520420; :>> 'FMI' = 2; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_diag.c:123 |frontKpa-frontKpaB| > 80 or |rearKpa-rearKpaB| > 80";
        }
        item 'DTC_A系電源' : '故障コード' {
            doc /* SPN 520430 FMI 4。24 V ネット A が 18..32 V の範囲外（bbw_diag.c:127-128）。ネット B と同時で FAULT（bbw_diag.c:146）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 34; symbol = "BBW_DTC_SUPPLY_A"; }
            :>> 'SPN' = 520430; :>> 'FMI' = 4; :>> critical = false; :>> '重大故障条件' = "BBW_DTC_SUPPLY_B";
            :>> '設定元' = "bbw_diag.c:127 supplyAmV < 18000 or > 32000";
        }
        item 'DTC_B系電源' : '故障コード' {
            doc /* SPN 520431 FMI 4。24 V ネット B が 18..32 V の範囲外（bbw_diag.c:129-130）。ネット A と同時で FAULT（bbw_diag.c:146）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 35; symbol = "BBW_DTC_SUPPLY_B"; }
            :>> 'SPN' = 520431; :>> 'FMI' = 4; :>> critical = false; :>> '重大故障条件' = "BBW_DTC_SUPPLY_A";
            :>> '設定元' = "bbw_diag.c:129 supplyBmV < 18000 or > 32000";
        }
        item 'DTCウォッチドッグリセット' : '故障コード' {
            doc /* SPN 520440 FMI 12。単独で critical（bbw_diag.c:36）。INIT の else 分岐で 1 回だけ HAL_WdgWasReset() を報告（bbw_state.c:103）。デバウンス 3 回に届かないため実際にはアクティブにならない（相違 D4）。 */
            @SourceTrace { file = "bbw_diag.c"; line = 36; symbol = "BBW_DTC_WDG_RESET"; }
            :>> 'SPN' = 520440; :>> 'FMI' = 12; :>> critical = true; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_state.c:103 INIT else branch, HAL_WdgWasReset()";
        }
        item 'DTC反応' : '故障コード' {
            doc /* SPN 520450 FMI 7。減速指令 >= 0.5 m/s^2 から 200 ms を超えても後軸圧 < 50 kPa（bbw_diag.c:100-107）。失敗を 3 回続けて報告し即時セット。 */
            @SourceTrace { file = "bbw_diag.c"; line = 37; symbol = "BBW_DTC_REACTION"; }
            :>> 'SPN' = 520450; :>> 'FMI' = 7; :>> critical = false; :>> '重大故障条件' = "";
            :>> '設定元' = "bbw_diag.c:100 rearKpa < 50 kPa more than 200 ms after demand >= 0.5 m/s^2";
        }

        // ---- operating modes (bbw_state.c:80): see state def BbwOperatingModes
        // (state usage removed in the merged file: the studio draws a usage typed
        // by a state def as an empty diagram; the def carries the machine)
    }

    /* ------------------------------------------------------------ */
    /* Discrepancies between comments, headers and code              */
    /* ------------------------------------------------------------ */

    comment discrepancyCmdTimeout /*
     * 相違 D1（bbw_can.h:10 と bbw_cfg.h:31 / bbw_can.c:113-114, 145-148）: ヘッダは指令タイムアウト
     * 40 ms と記載。コードは 5 周期 x 10 ms で、最後の正常フレームから 50 ms 後に無効化する。
     * モデルは 50 ms（cmdTimeout）。BBW-R2 はヘッダの 40 ms を要件として評価し、違反となる。
     */
    comment discrepancyDecelRange /*
     * 相違 D2（bbw_can.h:34 と bbw_can.c:86-89）: ヘッダは減速指令 0..10 m/s^2。コードは 7.0 m/s^2
     * （BBW_MAX_DECEL_MPS2）でクランプする。モデルは maximum = 7.0。
     */
    comment discrepancyIcdRevision /*
     * 相違 D3（bbw_can.h:7-8）: 正式な ICD は rev F だが、ヘッダは rev D にしか照合されていない。
     * メッセージ定義はコード（rev D 相当）をモデル化した。
     */
    comment discrepancyWdgResetDtc /*
     * 相違 D4（bbw_diag.c:36, bbw_diag.c:135 と bbw_state.c:101-104, bbw_diag.c:14）: WDG_RESET は
     * critical と定義されるが、INIT の else 分岐で 1 回報告されるだけで直後に FAULT へ移るため、
     * デバウンス（3 回）に達せずアクティブにならない。DM1 にも STATUS の DTC 数にも現れない。
     * また自己診断失敗（HAL_SelfTest() 偽、ウォッチドッグリセットなし）では合格が報告され、
     * FAULT の原因を示す DTC が一切残らない。
     */
    comment discrepancyE2eDtcHeal /*
     * 相違 D5（bbw_can.c:121-132 と bbw_diag.c:61-75）: E2E DTC は不良フレーム受信時にしか報告されず、
     * 正常フレームでは合格報告がない。一度セットされると、連続 1〜2 回の孤立した不良フレームが
     * 50 回起きない限り解除されず、実質的に電源再投入までラッチする。STANDBY から
     * AUTONOMOUS_ACTIVE への遷移はアクティブ DTC 数 0 を条件とする（bbw_state.c:112）ため、
     * 再エンゲージが阻止される。チャネル無効化は 3 回目、DTC セットは 5 回目の連続不良フレーム。
     */
    comment discrepancyReactionMonitor /*
     * 相違 D6（bbw_cfg.h:36-37 と bbw_diag.c:80-113）: 設定コメントは車両要件 JP-R3 の
     * 「指令から圧力上昇まで 0.2 s」を参照するが、監視の起点は CAN 受信ではなく内部減速指令
     * （BBW_StateDecelDemand）で、終点は後軸圧のみ。超過しても DTC（非 critical）と
     * STATUS byte6 bit4 だけで、モード遷移は起きない。DTC は合格報告が圧力上昇 1 回につき 1 回しか
     * ないため、STANDBY（指令 0）では解除されずエンゲージが阻止される。
     */
    comment discrepancyMaxSelect /*
     * 相違 D7（bbw_state.c:119-120）: コメントは「両チャネル正常時の max 選択」だが、コードは
     * 遷移判定の前に有効性を問わず max(pri, sec) を計算する。片側が無効になった周期は
     * その無効チャネルの最後の値（タイムアウトではリセットされない）も選択対象になる。
     */
    comment discrepancyDegradedName /*
     * 相違 D8（bbw_state.h:16 と bbw_state.c:133, 159）: 状態名 DEGRADED_SINGLE_CHANNEL は
     * 指令チャネルの片系喪失を示すが、コードは前軸または後軸モジュレータの喪失でも同じ状態に入り、
     * 復帰にも両モジュレータ正常を指令する。
     */
    comment discrepancySrsModeDiagram /*
     * 相違 D9（bbw_state.c:9）: SRS 4 章の状態遷移図は古いとコメントにある。DEGRADED から STANDBY
     * への直接遷移（field fix FR-2291、bbw_state.c:154-158）は SRS にない可能性が高い。
     * モデルは BBW_StateStep() の実装どおり。
     */
    comment discrepancyDm1Format /*
     * 相違 D10（bbw_diag.h:6, bbw_can.h:24 と bbw_can.c:199-217）: DTC は J1939 SPN/FMI 形式と
     * されるが、DM1 は 11 bit ID 0x3A0 で送られ、byte0 はランプ状態ではなく DTC 数、
     * 送るのは先頭のアクティブ DTC 1 件のみ、OC は 0xFF。標準 J1939 DM1 とは互換性がない。
     */
    comment gapSpeedSupervision /*
     * 未保護箇所 G1（bbw_can.c:134-137, bbw_can.h:65）: VEH_SPEED は CRC、カウンタ、タイムアウト監視が
     * いずれもない。起動時は speedKph = 0（bbw_can.c:61）なので standstill が真となり、
     * フレームが途絶えても最後の値を保持し続ける。停止判定は DISENGAGE から STANDBY への遷移と
     * MRC からパーキングブレーキへの引き渡しに使われる。PRESSURE と DM1 も E2E 保護なし。
     */
    comment gapParkBrakeRelease /*
     * 未実装 G2（bbw_hal.h:44, bbw_state.c:184, 201）: HAL_ParkBrake(false) はどこからも呼ばれない。
     * MRC_STOP 後の STANDBY でもパーキングブレーキは指令されたまま。解除は本ソフト外と推定。
     */
    comment gapModeRange /*
     * 未検査 G3（bbw_can.c:90）: XBR モード 4 bit の値 5..15 は検査されず格納される。
     * どの遷移条件にも一致しないため、現在状態に留まる。urgency（bbw_can.c:91）は未使用。
     */
    comment gapMrcRamp /*
     * 実装上の注意 G4（bbw_state.c:70-73）: MRC 入場時の指令が 3.0 m/s^2 を超える場合、
     * 下降ランプは目標でクランプされず、最大 0.025 m/s^2 だけ下回ってから上昇に戻り、
     * 目標付近で 1 周期ごとに振動する。
     */

    /* ------------------------------------------------------------ */
    /* Derived requirements                                          */
    /* ------------------------------------------------------------ */

    requirement def <'BBW-R1'> ReactionBudget {
        doc /* ブレーキ ECU の反応時間予算は車両の反応時間予算（JP-R3、0.2 s）以内であり、かつ制御周期と後軸モジュレータ応答時間の和はこの予算以内であること。出典 bbw_cfg.h:37 BBW_REACTION_BUDGET_MS。 */
        @SourceTrace { file = "bbw_cfg.h"; line = 37; symbol = "BBW_REACTION_BUDGET_MS"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'反応時間配分' <= t.'反応時間配分' }
        require constraint { t.'ブレーキECUソフトウェア'.'タスク周期' + t.'ドライブバイワイヤ'.'ブレーキ'.'後軸モジュレータ'.'応答時間' <= t.'ブレーキECUソフトウェア'.'反応時間配分' }
    }

    requirement def <'BBW-R2'> CommandTimeout {
        doc /* 各 XBR 指令チャネルの喪失は 40 ms 以内に検出すること（ヘッダ bbw_can.h:10 の記載）。コードの実装値は 50 ms（bbw_cfg.h:31、bbw_can.c:145）で、本要件は違反となる（相違 D1）。 */
        @SourceTrace { file = "bbw_can.h"; line = 10; symbol = "Command timeout"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'指令タイムアウト時間' <= 0.04 [s] }
    }

    requirement def <'BBW-R3'> CommandE2eProtection {
        doc /* 主系と冗長系の両方の XBR 指令チャネルは CRC-8 とローリングカウンタによる E2E 保護を持つこと。出典 bbw_can.c:66-105 BBW_DecodeXbr、bbw_can.c:121, 128。 */
        @SourceTrace { file = "bbw_can.c"; line = 66; symbol = "BBW_DecodeXbr"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'主系XBR指令'.'E2E保護あり' and t.'ブレーキECUソフトウェア'.'副系XBR指令'.'E2E保護あり' }
        require constraint { t.'ブレーキECUソフトウェア'.'主系XBR指令'.'カウンタビット数' >= 4 and t.'ブレーキECUソフトウェア'.'副系XBR指令'.'カウンタビット数' >= 4 }
    }

    requirement def <'BBW-R4'> WatchdogWindow {
        doc /* ウォッチドッグの処理周期はウィンドウ（5 ms 〜 30 ms）内にあり、ソフトのタイムアウト設定は ECU ハードウェアのウォッチドッグタイムアウト以下であること。出典 bbw_cfg.h:27-28、bbw_main.c:74。 */
        @SourceTrace { file = "bbw_main.c"; line = 74; symbol = "HAL_WdgService"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'ウォッチドッグ窓開' < t.'ブレーキECUソフトウェア'.'ウォッチドッグ処理周期' and t.'ブレーキECUソフトウェア'.'ウォッチドッグ処理周期' < t.'ブレーキECUソフトウェア'.'ウォッチドッグ時間' }
        require constraint { t.'ブレーキECUソフトウェア'.'ウォッチドッグ時間' <= t.'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'ウォッチドッグタイムアウト' }
    }

    requirement def <'BBW-R5'> TaskPeriodConsistency {
        doc /* ソフトウェアの制御周期と XBR 指令周期は、ECU ハードウェアの制御周期と CAN ポート周期以下であること。出典 bbw_cfg.h:22、bbw_can.h:19-20。 */
        @SourceTrace { file = "bbw_cfg.h"; line = 22; symbol = "BBW_TASK_PERIOD_MS"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'タスク周期' <= t.'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'タスク周期' }
        require constraint { t.'ブレーキECUソフトウェア'.'主系XBR指令'.'周期' <= t.'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'主系CAN端子'.'周期' and t.'ブレーキECUソフトウェア'.'副系XBR指令'.'周期' <= t.'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'副系CAN端子'.'周期' }
    }

    requirement def <'BBW-R6'> DegradedTimeLimit {
        doc /* 単一チャネルでの縮退運転は 60 s 以内に MRC 停止へ移行すること。出典 bbw_cfg.h:51、bbw_state.c:150-152。 */
        @SourceTrace { file = "bbw_state.c"; line = 150; symbol = "BBW_DEGRADED_MAX_MS"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'縮退最大時間' <= 60 [s] }
    }

    requirement def <'BBW-R7'> MrcProfile {
        doc /* MRC 停止の目標減速度は 3.0 m/s^2 以上かつ減速指令上限以下、ジャークは 2.5 m/s^3 以下であること。出典 bbw_cfg.h:49-50、bbw_state.c:62-78。 */
        @SourceTrace { file = "bbw_state.c"; line = 62; symbol = "BBW_MrcRamp"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'MRC減速度' >= 3.0 [m/s^2] and t.'ブレーキECUソフトウェア'.'MRC減速度' <= t.'ブレーキECUソフトウェア'.'最大減速度' }
        require constraint { t.'ブレーキECUソフトウェア'.'MRC躍度' <= 2.5 }
    }

    requirement def <'BBW-R8'> CommandChannelRedundancy {
        doc /* ソフトウェアはブレーキバイワイヤに指令される数（JP-R7）以上の独立した指令チャネルを調停すること。出典 bbw_can.h:81-86 BbwCanRx_t、bbw_state.c:82-83。 */
        @SourceTrace { file = "bbw_state.c"; line = 82; symbol = "g_bbwRx.pri"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'指令系統数' >= t.'ドライブバイワイヤ'.'ブレーキ'.'指令系統数' }
    }

    requirement def <'BBW-R9'> ParkBrakeHandover {
        doc /* MRC 停止後の停止保持時間は、パーキングブレーキモジュールの作動時間以上であること。出典 bbw_cfg.h:53、bbw_state.c:179-188。 */
        @SourceTrace { file = "bbw_state.c"; line = 182; symbol = "BBW_STANDSTILL_HOLD_MS"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'停止保持' >= t.'ドライブバイワイヤ'.'ブレーキ'.'駐車ブレーキ'.'作動時間' }
    }

    requirement def <'BBW-R10'> PressureLimit {
        doc /* ソフトウェアの指令圧上限は前軸と後軸のモジュレータの最大供給圧以下であること。出典 bbw_cfg.h:44、bbw_main.c:26。 */
        @SourceTrace { file = "bbw_main.c"; line = 26; symbol = "BBW_MAX_PRESSURE_KPA"; }
        subject t : '自動運転トラック';
        require constraint { t.'ブレーキECUソフトウェア'.'最大圧力' <= t.'ドライブバイワイヤ'.'ブレーキ'.'前軸モジュレータ'.'最大吐出圧' and t.'ブレーキECUソフトウェア'.'最大圧力' <= t.'ドライブバイワイヤ'.'ブレーキ'.'後軸モジュレータ'.'最大吐出圧' }
    }

    requirement 'BBW反応時間配分要件' : ReactionBudget;
    requirement 'BBW指令タイムアウト要件' : CommandTimeout;
    requirement 'BBW指令E2E保護要件' : CommandE2eProtection;
    requirement 'BBWウォッチドッグ要件' : WatchdogWindow;
    requirement 'BBWタスク周期要件' : TaskPeriodConsistency;
    requirement 'BBW縮退時間制限要件' : DegradedTimeLimit;
    requirement 'BBW_MRC減速プロファイル要件' : MrcProfile;
    requirement 'BBW系統冗長要件' : CommandChannelRedundancy;
    requirement 'BBW駐車ブレーキ移行要件' : ParkBrakeHandover;
    requirement 'BBW圧力上限要件' : PressureLimit;
}

package 'L4自動運転大型キャブオーバー車' {
    doc /*
     * 大型キャブオーバー L4 自動運転トラック（車両総重量 25 t、8x4 低床 4 軸、ウイング車）。
     * 日本の高速道路の物流拠点間輸送（例：新東名高速道路の自動運転優先レーンを使う、
     * サービスエリア併設の物流拠点どうしの幹線輸送）を、運転者なしで行う（SAE レベル 4）。
     * 日本の車両制限（全長 12 m、全幅 2.5 m、全高 3.8 m、総重量 25 t、軸重 10 t）に収める。
     * 右ハンドル、左側通行、24 V 電装、単位はメートル法。
     */
    private import ISQ::*;
    private import SI::*;
    private import ScalarValues::*;
    private import ShapeItems::*;
    private import MBEstudio::*;
    private import '大型キャブオーバー車インタフェース'::*;
    private import '大型キャブオーバー車部品'::*;
    private import 'ブレーキECUリバースモデル'::*;

    /* ------------------------------------------------------------ */
    /* システム                                                       */
    /* ------------------------------------------------------------ */

    part def '自動運転トラック' {
        doc /*
         * 大型キャブオーバー 8x4 低床トラック（前 2 軸操舵、後 2 軸駆動の 2 デフ）、ウイング荷箱、
         * 自動運転レベル 4。車両総重量は全部品の質量と最大積載量の和。軸重は前後方向の重心位置から
         * 静的なつり合いで求め、前 2 軸と後 2 軸はそれぞれ均等に分担するものとする。
         * 原点は全長の中央の地面、x 前方、y 左、z 上（メートル）。
         */
        @Placement { mode = LayoutMode::fixed; }

        attribute '車両総重量上限' : MassValue = 25000 [kg];
        attribute '軸重上限' : MassValue = 10000 [kg];
        attribute '後2軸荷重上限' : MassValue = 18000 [kg];
        attribute '全長上限' : LengthValue = 12.0 [m];
        attribute '全幅上限' : LengthValue = 2.5 [m];
        attribute '全高上限' : LengthValue = 3.8 [m];
        attribute '反応時間配分' : DurationValue = 0.2 [s];
        attribute '空気密度' : Real = 1.2;
        attribute '空気抵抗面積m2' : Real = 5.3;
        attribute '巡航速度ms' : Real = 80.0 / 3.6;
        attribute 'ODD最高速度kmh' : Real = 80.0;
        attribute '法定最高速度kmh' : Real = 90.0;
        attribute '速度抑制装置kmh' : Real = 90.0;
        attribute '車線変更時間' : DurationValue = 8 [s];
        attribute 'MRM時間上限' : DurationValue = 30 [s];
        attribute 'タイヤ路面摩擦係数' : Real = 0.8;
        attribute 'R13最低減速度' : Real = 5.0;
        attribute '自動運転作動中' : Boolean default false;
        attribute 'MRC作動中' : Boolean default false;
        attribute '遠隔支援リクエスト' : Boolean default false;

        part 'キャブ' : 'キャブオーバーキャブ' { @Placement { xM = 4.815; yM = 0.0; zM = 2.3; } }
        part 'シャシ' : 'はしご形フレーム' { @Placement { xM = 0.07; yM = 0.0; zM = 0.5; } }
        part 'パワートレイン' : 'ディーゼルパワートレイン' { @Placement { xM = 1.7; yM = 0.02; zM = 0.9475; } @Routed { medium = "power"; } }
        part 'ボデー' : 'ウイングボデー' { @Placement { xM = -1.25; yM = 0.0; zM = 2.4; } }
        part '認識センサ群' : '認識センサ群型' { @Placement { xM = -0.0025; yM = 0.0; zM = 2.115; } @Routed { medium = "signal"; } }
        part '車載ネットワーク' : '車載ネットワーク型' { @Placement { xM = 0.359; yM = -0.1352; zM = 1.322; } @Routed { medium = "signal"; } }
        part 'ドライブバイワイヤ' : 'ドライブバイワイヤ型' { @Placement { xM = 0.3512; yM = 0.0; zM = 0.7865; } @Routed { medium = "signal"; } }
        part 'ブレーキECUソフトウェア' : 'BBW_ECUソフトウェア' { @Placement { xM = 3.565; yM = 0.0; zM = 2.0; } }
        part '電源系' : '二重系電源システム' { @Placement { xM = 2.4875; yM = -0.105; zM = 1.2537; } @Routed { medium = "power"; } }
        part '熱管理' : '熱管理システム' { @Placement { xM = 4.95; yM = 0.0; zM = 1.225; } @Routed { medium = "fluid"; } }
        part '遠隔支援' : '遠隔監視ユニット' { @Placement { xM = 3.85; yM = 0.0; zM = 3.64; } }

        /* 寸法 */
        attribute '全長' : LengthValue = 'キャブ'.'キャブ長' + 0.15 [m] + 'ボデー'.'ボデー長';
        attribute '最遠軸距' : LengthValue = 7.9 [m];
        attribute 'ホイールベース' : LengthValue = 6.6 [m];
        attribute '軸配置長' : LengthValue = 1.4 [m] + 7.25 [m] + 3.33 [m];
        attribute '全幅' : LengthValue = 'ボデー'.'ボデー幅';
        attribute 'キャブ幅' : LengthValue = 'キャブ'.'キャブ幅';
        attribute '全高' : LengthValue = 1.01 [m] + 'ボデー'.'ボデー高さ';
        attribute 'キャブ上端高さ' : LengthValue = 1.0 [m] + 'キャブ'.'外形高さ';
        attribute 'センサ上端高さ' : LengthValue = '認識センサ群'.'上端高さ';

        /* 質量と軸重 */
        attribute payload : MassValue = 'ボデー'.'荷室'.'最大積載量';
        attribute '車両重量' : MassValue = 'キャブ'.mass + 'シャシ'.mass + 'パワートレイン'.mass + 'ボデー'.mass + '認識センサ群'.mass + '車載ネットワーク'.mass + 'ドライブバイワイヤ'.mass + '電源系'.mass + '熱管理'.mass + '遠隔支援'.mass;
        attribute '車両総重量' : MassValue = '車両重量' + payload;
        attribute '車両総重量kg' : Real = '車両総重量' / (1 [kg]);
        attribute '重心前後位置' : Real = (
            ('キャブ'.mass - 'キャブ'.'計算機'.mass - 'キャブ'.'記録装置'.mass) / (1 [kg]) * 4.815
            + ('キャブ'.'計算機'.mass) / (1 [kg]) * 3.95
            + ('キャブ'.'記録装置'.mass) / (1 [kg]) * 5.5
            + ('シャシ'.'フレーム組立質量') / (1 [kg]) * 0.07
            + ('シャシ'.'第1軸'.mass) / (1 [kg]) * 4.59
            + ('シャシ'.'第2軸'.mass) / (1 [kg]) * 2.79
            + ('シャシ'.'後前軸'.mass) / (1 [kg]) * -2.01
            + ('シャシ'.'後後軸'.mass) / (1 [kg]) * -3.31
            + ('パワートレイン'.mass - 'パワートレイン'.'燃料装置'.mass) / (1 [kg]) * 3.4
            + ('パワートレイン'.'燃料装置'.mass) / (1 [kg]) * 1.6
            + ('ボデー'.mass) / (1 [kg]) * -1.25
            + ('認識センサ群'.mass) / (1 [kg]) * 4.4
            + ('車載ネットワーク'.mass) / (1 [kg]) * 3.0
            + ('ドライブバイワイヤ'.mass) / (1 [kg]) * 1.9
            + ('電源系'.mass) / (1 [kg]) * 1.2
            + ('熱管理'.mass) / (1 [kg]) * 5.2
            + ('遠隔支援'.mass) / (1 [kg]) * 3.85
            + payload / (1 [kg]) * -1.46) / '車両総重量kg';
        attribute '前2軸位置' : Real = 3.69;
        attribute '後2軸位置' : Real = -2.66;
        attribute '前2軸荷重' : MassValue = '車両総重量' * ('重心前後位置' - '後2軸位置') / ('前2軸位置' - '後2軸位置');
        attribute '後2軸荷重' : MassValue = '車両総重量' - '前2軸荷重';
        attribute '第1軸重' : MassValue = '前2軸荷重' / 2;
        attribute '第2軸重' : MassValue = '前2軸荷重' / 2;
        attribute '後前軸重' : MassValue = '後2軸荷重' / 2;
        attribute '後後軸重' : MassValue = '後2軸荷重' / 2;

        /* 航続距離（80 km/h 巡航） */
        attribute '空気抵抗損失W' : Real = 0.5 * '空気密度' * '空気抵抗面積m2' * '巡航速度ms' ** 3;
        attribute '転がり抵抗損失W' : Real = 'シャシ'.'第1軸'.'転がり抵抗係数' * '車両総重量kg' * 9.81 * '巡航速度ms';
        attribute '走行1kmあたりエネルギーkWh' : Real = ('空気抵抗損失W' + '転がり抵抗損失W') / '巡航速度ms' / 3600.0 / 'パワートレイン'.efficiency;
        attribute '航続距離km' : Real = 'パワートレイン'.'燃料装置'.'使用可能エネルギー' / (1 [kW * h]) / '走行1kmあたりエネルギーkWh';

        /* 制動性能（UN R13 タイプ 0）と停止距離 */
        attribute '制動トルク合計Nm' : Real = 'シャシ'.'第1軸'.'左ホイールエンド'.'ディスクブレーキ'.'最大トルクNm' + 'シャシ'.'第1軸'.'右ホイールエンド'.'ディスクブレーキ'.'最大トルクNm'
            + 'シャシ'.'第2軸'.'左ホイールエンド'.'ディスクブレーキ'.'最大トルクNm' + 'シャシ'.'第2軸'.'右ホイールエンド'.'ディスクブレーキ'.'最大トルクNm'
            + 'シャシ'.'後前軸'.'左ホイールエンド'.'ドラムブレーキ'.'最大トルクNm' + 'シャシ'.'後前軸'.'右ホイールエンド'.'ドラムブレーキ'.'最大トルクNm'
            + 'シャシ'.'後後軸'.'左ホイールエンド'.'ドラムブレーキ'.'最大トルクNm' + 'シャシ'.'後後軸'.'右ホイールエンド'.'ドラムブレーキ'.'最大トルクNm';
        attribute '制動減速能力' : Real = '制動トルク合計Nm' / ('シャシ'.'第1軸'.'タイヤ半径' / (1 [m])) / '車両総重量kg';
        attribute '路面限界減速度' : Real = 'タイヤ路面摩擦係数' * 9.81;
        attribute 'ODD速度ms' : Real = 'ODD最高速度kmh' / 3.6;
        attribute '停止距離m' : Real = 'ODD速度ms' * '反応遅れ' / (1 [s]) + 'ODD速度ms' * 'ODD速度ms' / (2 * 'R13最低減速度');
        attribute 'MRM停止までの時間' : DurationValue = '車線変更時間' + 'ODD速度ms' / ('ブレーキECUソフトウェア'.'MRC減速度' / (1 [m/s^2])) * (1 [s]);

        /* 自動運転 */
        attribute '反応遅れ' : DurationValue = '認識センサ群'.'前方LiDAR'.latency + '認識センサ群'.'センサスイッチ'.'ホップ遅れ' + 'キャブ'.'計算機'.'判断遅れ' + 'ドライブバイワイヤ'.'ブレーキ遅れ';
        attribute 'フォールバック遅れ' : DurationValue = 'キャブ'.'計算機'.'フォールバック遅れ' + 'ドライブバイワイヤ'.'ゲートウェイ遅れ';
        attribute 'センサ総データ量Mbps' : Real = '認識センサ群'.'総データ量Mbps';
        attribute 'A系負荷' : PowerValue = '認識センサ群'.'消費電力' + 'キャブ'.'計算機'.'主計算機'.'消費電力' + 'キャブ'.'計算機'.'ネットワークスイッチ'.'消費電力'
            + '車載ネットワーク'.'ゲートウェイ'.'消費電力' + 'ドライブバイワイヤ'.'操舵装置'.'消費電力' / 2 + 'ドライブバイワイヤ'.'ブレーキ'.'消費電力' / 2 + 'ドライブバイワイヤ'.'スロットル'.'消費電力' / 2
            + '遠隔支援'.'消費電力' + 'キャブ'.'記録装置'.'消費電力' + 'キャブ'.'HMI'.'消費電力' + 'キャブ'.'空調'.'消費電力' + '熱管理'.'計算機冷却ループ'.'消費電力';
        attribute 'B系負荷' : PowerValue = 'キャブ'.'計算機'.'フォールバック計算機'.'消費電力' + 'キャブ'.'計算機'.'安全監視装置'.'消費電力' + 'キャブ'.'計算機'.'時刻マスタ'.'消費電力'
            + '車載ネットワーク'.'B系バックボーンスイッチ'.'消費電力' + 'ドライブバイワイヤ'.'操舵装置'.'消費電力' / 2 + 'ドライブバイワイヤ'.'ブレーキ'.'消費電力' / 2 + 'ドライブバイワイヤ'.'スロットル'.'消費電力' / 2;
        attribute 'バックアップ保持時間' : DurationValue = '電源系'.'バックアップ電池'.energy / 'B系負荷';

        /* 動力と燃料 */
        interface 'プロペラシャフトから後2軸へ' : 'ドライブライン' connect '主側' ::> 'パワートレイン'.'プロペラシャフト'.'出力' to '被駆動側' ::> 'シャシ'.'後前軸'.'駆動入力';
        interface '軸間動力伝達' : 'ドライブライン' connect '主側' ::> 'シャシ'.'後前軸'.'スルー出力' to '被駆動側' ::> 'シャシ'.'後後軸'.'駆動入力';

        /* 構造 */
        interface '第1軸取付' : '車軸取付' connect '構造' ::> 'シャシ'.'操舵軸ハンガ' to '車軸' ::> 'シャシ'.'第1軸'.'取付部';
        interface '第2軸取付' : '車軸取付' connect '構造' ::> 'シャシ'.'操舵軸ハンガ' to '車軸' ::> 'シャシ'.'第2軸'.'取付部';
        interface '後前軸取付' : '車軸取付' connect '構造' ::> 'シャシ'.'後2軸ハンガ' to '車軸' ::> 'シャシ'.'後前軸'.'取付部';
        interface '後後軸取付' : '車軸取付' connect '構造' ::> 'シャシ'.'後2軸ハンガ' to '車軸' ::> 'シャシ'.'後後軸'.'取付部';
        interface 'ボデー架装' : 'ボデー取付' connect 'シャシ側' ::> 'シャシ'.'ボデー取付部' to 'ボデー' ::> 'ボデー'.'取付部';

        /* Ethernet バックボーン（10GBASE-T1、TSN） */
        interface 'センサアップリンク' : 'Ethernetリンク' connect '端A' ::> '認識センサ群'.'センサスイッチ'.'アップリンク' to '端B' ::> 'キャブ'.'計算機'.'ネットワークスイッチ'.'Ethernet端子';
        interface 'バックボーンリング' : 'Ethernetリンク' connect '端A' ::> 'キャブ'.'計算機'.'ネットワークスイッチ'.'Ethernet端子' to '端B' ::> '車載ネットワーク'.'B系バックボーンスイッチ'.'Ethernet端子';
        interface 'フォールバック計算機データ' : 'Ethernetリンク' connect '端A' ::> 'キャブ'.'計算機'.'フォールバック計算機'.'Ethernet端子' to '端B' ::> '車載ネットワーク'.'B系バックボーンスイッチ'.'Ethernet端子';
        interface '遠隔支援データ' : 'Ethernetリンク' connect '端A' ::> '遠隔支援'.'Ethernet端子' to '端B' ::> '車載ネットワーク'.'B系バックボーンスイッチ'.'Ethernet端子';

        /* gPTP 時刻同期 */
        interface 'PPS同期' : '時刻同期リンク' connect 'マスタ' ::> '認識センサ群'.'GNSS_IMU'.'PPS' to 'スレーブ' ::> 'キャブ'.'計算機'.'時刻マスタ'.'PPS入力';
        interface 'センサスイッチPTP' : '時刻同期リンク' connect 'マスタ' ::> 'キャブ'.'計算機'.'時刻マスタ'.'PTP' to 'スレーブ' ::> '認識センサ群'.'センサスイッチ'.'PTP';
        interface 'LiDAR_PTP' : '時刻同期リンク' connect 'マスタ' ::> 'キャブ'.'計算機'.'時刻マスタ'.'PTP' to 'スレーブ' ::> '認識センサ群'.'前方LiDAR'.'PTP';
        interface 'レーダPTP' : '時刻同期リンク' connect 'マスタ' ::> 'キャブ'.'計算機'.'時刻マスタ'.'PTP' to 'スレーブ' ::> '認識センサ群'.'前方レーダ'.'PTP';
        interface 'カメラPTP' : '時刻同期リンク' connect 'マスタ' ::> 'キャブ'.'計算機'.'時刻マスタ'.'PTP' to 'スレーブ' ::> '認識センサ群'.'狭角カメラ'.'PTP';

        /* 指令系 CAN FD：A は主系、B は冗長系 */
        interface '主計算機からシャシCAN_A系へ' : 'CANリンク' connect '端A' ::> 'キャブ'.'計算機'.'主計算機'.'CAN' to '端B' ::> '車載ネットワーク'.'シャシCAN_A系'.'ノード';
        interface 'フォールバック計算機からシャシCAN_B系へ' : 'CANリンク' connect '端A' ::> 'キャブ'.'計算機'.'フォールバック計算機'.'CAN' to '端B' ::> '車載ネットワーク'.'シャシCAN_B系'.'ノード';
        interface 'ブレーキECU_A系バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_A系'.'ノード' to '端B' ::> 'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'主系CAN端子';
        interface 'ブレーキECU_B系バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_B系'.'ノード' to '端B' ::> 'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'副系CAN端子';
        interface '操舵ECU_A系バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_A系'.'ノード' to '端B' ::> 'ドライブバイワイヤ'.'操舵装置'.'A系操舵ECU'.'CAN';
        interface '操舵ECU_B系バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_B系'.'ノード' to '端B' ::> 'ドライブバイワイヤ'.'操舵装置'.'B系操舵ECU'.'CAN';
        interface 'スロットルバス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_A系'.'ノード' to '端B' ::> 'ドライブバイワイヤ'.'スロットル'.'シャシCAN端子';
        interface '安全監視バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_B系'.'ノード' to '端B' ::> 'キャブ'.'計算機'.'安全監視装置'.'フォールバックCAN端子';
        interface 'エンジンへのトルクリクエスト' : 'CANリンク' connect '端A' ::> 'ドライブバイワイヤ'.'スロットル'.'パワートレインCAN端子' to '端B' ::> 'パワートレイン'.'エンジン'.'ECM'.'CAN';
        interface '変速機バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'パワートレインCAN'.'ノード' to '端B' ::> 'パワートレイン'.'変速機'.'TCU'.'CAN';
        interface 'ECASバス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_A系'.'ノード' to '端B' ::> 'シャシ'.'ECAS'.'CAN';
        interface 'ボデーバス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'ボデーCAN'.'ノード' to '端B' ::> 'ボデー'.'CAN';
        interface 'HMIバス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'ボデーCAN'.'ノード' to '端B' ::> 'キャブ'.'HMI'.'CAN';
        interface '記録装置バス' : 'CANリンク' connect '端A' ::> '車載ネットワーク'.'シャシCAN_A系'.'ノード' to '端B' ::> 'キャブ'.'記録装置'.'CAN';

        /* 空気ブレーキ：モジュレータからホイールのチャンバへ */
        interface '第1軸左チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'前左ABS弁'.'送出' to '送出' ::> 'シャシ'.'第1軸'.'左ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '第1軸右チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'前右ABS弁'.'送出' to '送出' ::> 'シャシ'.'第1軸'.'右ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '第2軸左チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'前軸モジュレータ'.'送出' to '送出' ::> 'シャシ'.'第2軸'.'左ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '第2軸右チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'前軸モジュレータ'.'送出' to '送出' ::> 'シャシ'.'第2軸'.'右ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '後前軸左チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'後軸モジュレータ'.'送出' to '送出' ::> 'シャシ'.'後前軸'.'左ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '後後軸左チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'後軸モジュレータ'.'送出' to '送出' ::> 'シャシ'.'後後軸'.'左ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '後前軸右チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'後軸モジュレータ'.'右送出口' to '送出' ::> 'シャシ'.'後前軸'.'右ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface '後後軸右チャンバ配管' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'後軸モジュレータ'.'右送出口' to '送出' ::> 'シャシ'.'後後軸'.'右ホイールエンド'.'ブレーキチャンバ'.'空気入口';
        interface 'サスペンション給気' : 'エア配管' connect '供給' ::> 'ドライブバイワイヤ'.'ブレーキ'.'空気供給'.'サスペンション用エアタンク'.'出口' to '送出' ::> 'シャシ'.'車高調整バルブ'.'空気入口';

        /* 計算機の冷却 */
        interface '主計算機冷却' : '冷却水回路' connect source ::> '熱管理'.'計算機冷却ループ'.'供給' to '受け側' ::> 'キャブ'.'計算機'.'主計算機'.'冷却水';
        interface 'フォールバック計算機冷却' : '冷却水回路' connect source ::> '熱管理'.'計算機冷却ループ'.'供給' to '受け側' ::> 'キャブ'.'計算機'.'フォールバック計算機'.'冷却水';

        /* 24 V ネット A：負荷ごとに PDU A の名前付き eFuse チャネル */
        interface '前方LiDAR給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'前方LiDAR用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'前方LiDAR'.'24V電源';
        interface '前左LiDAR給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'コーナーLiDAR用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'前左LiDAR'.'24V電源';
        interface '前右LiDAR給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'コーナーLiDAR用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'前右LiDAR'.'24V電源';
        interface '後左LiDAR給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'コーナーLiDAR用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'後左LiDAR'.'24V電源';
        interface '後右LiDAR給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'コーナーLiDAR用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'後右LiDAR'.'24V電源';
        interface '前方レーダ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'レーダ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'前方レーダ'.'24V電源';
        interface '前左レーダ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'レーダ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'前左レーダ'.'24V電源';
        interface '前右レーダ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'レーダ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'前右レーダ'.'24V電源';
        interface '後左レーダ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'レーダ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'後左レーダ'.'24V電源';
        interface '後右レーダ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'レーダ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'後右レーダ'.'24V電源';
        interface '狭角カメラ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'カメラ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'狭角カメラ'.'24V電源';
        interface '広角カメラ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'カメラ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'広角カメラ'.'24V電源';
        interface '左側方カメラ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'カメラ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'左側方カメラ'.'24V電源';
        interface '右側方カメラ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'カメラ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'右側方カメラ'.'24V電源';
        interface '後方カメラ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'カメラ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'後方カメラ'.'24V電源';
        interface '赤外線カメラ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'カメラ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'赤外線カメラ'.'24V電源';
        interface 'GNSS給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'GNSS用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'GNSS_IMU'.'24V電源';
        interface 'センサスイッチ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'センサスイッチ用ヒューズ'.'負荷側' to '負荷' ::> '認識センサ群'.'センサスイッチ'.'24V電源';
        interface '主計算機給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'主計算機用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'計算機'.'主計算機'.'24V電源';
        interface 'A系バックボーン給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'A系バックボーン用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'計算機'.'ネットワークスイッチ'.'24V電源';
        interface 'ゲートウェイ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'ゲートウェイ用ヒューズ'.'負荷側' to '負荷' ::> '車載ネットワーク'.'ゲートウェイ'.'24V電源';
        interface 'A系安全監視給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'安全監視装置用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'計算機'.'安全監視装置'.'24V電源';
        interface 'A系操舵給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'操舵用ヒューズ'.'負荷側' to '負荷' ::> 'ドライブバイワイヤ'.'操舵装置'.'24V電源';
        interface 'A系ブレーキ給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'ブレーキ用ヒューズ'.'負荷側' to '負荷' ::> 'ドライブバイワイヤ'.'ブレーキ'.'24V電源';
        interface 'A系スロットル給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'スロットル用ヒューズ'.'負荷側' to '負荷' ::> 'ドライブバイワイヤ'.'スロットル'.'24V電源';
        interface '遠隔支援給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'遠隔支援用ヒューズ'.'負荷側' to '負荷' ::> '遠隔支援'.'24V電源';
        interface '記録装置給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'記録装置用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'記録装置'.'24V電源';
        interface 'HMI給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'HMI用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'HMI'.'24V電源';
        interface '計算機冷却給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'計算機冷却用ヒューズ'.'負荷側' to '負荷' ::> '熱管理'.'計算機冷却ループ'.'24V電源';
        interface 'ボデー給電' : '24V給電線' connect supplier ::> '電源系'.'A系電源分配ユニット'.'ボデー用ヒューズ'.'負荷側' to '負荷' ::> 'ボデー'.'24V電源';

        /* 24 V ネット B（LFP バックアップ）：フェールオペレーショナル負荷 */
        interface 'フォールバック計算機給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'フォールバック計算機用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'計算機'.'フォールバック計算機'.'24V電源';
        interface 'B系安全監視給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'安全監視装置用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'計算機'.'安全監視装置'.'B系24V電源';
        interface 'B系操舵給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'操舵用ヒューズ'.'負荷側' to '負荷' ::> 'ドライブバイワイヤ'.'操舵装置'.'B系24V電源';
        interface 'B系ブレーキ給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'ブレーキ用ヒューズ'.'負荷側' to '負荷' ::> 'ドライブバイワイヤ'.'ブレーキ'.'B系24V電源';
        interface 'B系スロットル給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'スロットル用ヒューズ'.'負荷側' to '負荷' ::> 'ドライブバイワイヤ'.'スロットル'.'B系24V電源';
        interface 'B系バックボーン給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'B系バックボーン用ヒューズ'.'負荷側' to '負荷' ::> '車載ネットワーク'.'B系バックボーンスイッチ'.'24V電源';
        interface '時刻マスタ給電' : '24V給電線' connect supplier ::> '電源系'.'B系電源分配ユニット'.'時刻マスタ用ヒューズ'.'負荷側' to '負荷' ::> 'キャブ'.'計算機'.'時刻マスタ'.'24V電源';

        constraint '車両総重量が上限内' { '車両総重量' <= '車両総重量上限' }
        constraint '反応時間が配分内' { '反応遅れ' <= '反応時間配分' }
        constraint '全長が軸配置と整合' { '軸配置長' <= '全長上限' }

        state '走行モード' {
            doc /* 物流拠点間の運行モード。状態の entry で車両の属性を書き換える。 */
            entry; then '拠点で駐車中';
            state '拠点で駐車中' { entry assign '自動運転作動中' := false; }
            state '運行前点検' { entry assign 'MRC作動中' := false; }
            state '拠点構内徐行' { entry assign '自動運転作動中' := true; }
            state '高速道路へ合流';
            state '優先レーン巡航';
            state '拠点へ退出';
            state 'ミニマルリスクマヌーバ' { entry assign 'MRC作動中' := true; }
            state 'ミニマルリスク状態' { entry assign '遠隔支援リクエスト' := true; }
            state '遠隔解除' { entry assign 'MRC作動中' := false; }
            transition '点検開始' first '拠点で駐車中' accept after 600 [s] then '運行前点検';
            transition '点検合格' first '運行前点検' accept after 900 [s] then '拠点構内徐行';
            transition '出場' first '拠点構内徐行' accept after 240 [s] then '高速道路へ合流';
            transition '合流完了' first '高速道路へ合流' accept after 60 [s] then '優先レーン巡航';
            transition '出口へ接近' first '優先レーン巡航' accept after 16200 [s] then '拠点へ退出';
            transition '入場' first '拠点へ退出' accept after 300 [s] then '拠点で駐車中';
            transition '走行中に故障' first '優先レーン巡航' then 'ミニマルリスクマヌーバ';
            transition '合流中に故障' first '高速道路へ合流' then 'ミニマルリスクマヌーバ';
            transition '路肩停止完了' first 'ミニマルリスクマヌーバ' accept after 40 [s] then 'ミニマルリスク状態';
            transition '運行管理者確認済み' first 'ミニマルリスク状態' accept after 900 [s] then '遠隔解除';
            transition '再開' first '遠隔解除' then '優先レーン巡航';
        }
    }

    part 'キャブオーバー車' : '自動運転トラック' {
        allocate 'ブレーキECUソフトウェア' to 'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU';
    }

    /* ------------------------------------------------------------ */
    /* 要件                                                           */
    /* ------------------------------------------------------------ */

    requirement def <'JP-R1'> OverallLengthRequirement {
        doc /* 車両の全長は 12 m 以下であること（道路運送車両の保安基準 第 2 条）。キャブ、キャブと荷箱のすき間、荷箱の外のり長さの和で検証する。 */
        subject t : '自動運転トラック';
        require constraint { t.'全長' <= t.'全長上限' }
    }

    requirement def <'JP-R2'> OverallWidthRequirement {
        doc /* 車両の全幅は 2.5 m 以下であること（保安基準 第 2 条）。荷箱とキャブの幅で検証する（後写鏡とカメラアームは除く）。 */
        subject t : '自動運転トラック';
        require constraint { t.'全幅' <= t.'全幅上限' }
        require constraint { t.'キャブ幅' <= t.'全幅上限' }
    }

    requirement def <'JP-R3'> ReactionLatencyRequirement {
        doc /* 障害物が前方 LiDAR の視野に入ってから、後軸ブレーキの圧力が立ち上がり始めるまでを 0.2 s 以内とすること（LiDAR 1 フレーム、スイッチ、計算機、ゲートウェイ、EBS 制御周期、モジュレータ応答の和）。 */
        subject t : '自動運転トラック';
        require constraint { t.'反応遅れ' <= t.'反応時間配分' }
    }

    requirement def <'JP-R4'> OverallHeightRequirement {
        doc /* 車両の全高は 3.8 m 以下であること（保安基準 第 2 条）。荷箱上面、キャブのエアデフレクタ上端、屋根上センサの上端のいずれも超えないこと。 */
        subject t : '自動運転トラック';
        require constraint { t.'全高' <= t.'全高上限' }
        require constraint { t.'キャブ上端高さ' <= t.'全高上限' }
        require constraint { t.'センサ上端高さ' <= t.'全高上限' }
    }

    requirement def <'JP-R5'> GrossVehicleMassRequirement {
        doc /* 最大積載時の車両総重量は 25 t 以下であること。25 t の上限は長さ 11 m 以上かつ最遠軸距 7 m 以上の車両に適用される（保安基準 第 4 条、車両制限令 第 3 条）。 */
        subject t : '自動運転トラック';
        require constraint { t.'車両総重量' <= t.'車両総重量上限' }
        require constraint { t.'最遠軸距' >= 7.0 [m] }
        require constraint { t.'全長' >= 11.0 [m] }
    }

    requirement def <'JP-R6'> AxleLoadRequirement {
        doc /* 最大積載時の各軸重は 10 t 以下、後 2 軸（隣接軸）の合計は 18 t 以下であること（保安基準 第 4 条の 2）。第 1 軸、第 2 軸、第 3 軸、第 4 軸のそれぞれで検証する。 */
        subject t : '自動運転トラック';
        require constraint { t.'第1軸重' <= t.'軸重上限' }
        require constraint { t.'第2軸重' <= t.'軸重上限' }
        require constraint { t.'後前軸重' <= t.'軸重上限' }
        require constraint { t.'後後軸重' <= t.'軸重上限' }
        require constraint { t.'後2軸荷重' <= t.'後2軸荷重上限' }
    }

    requirement def <'JP-R7'> BrakeRedundancyRequirement {
        doc /* ブレーキバイワイヤは 2 系統の独立した指令チャネルと 2 系統の電源を持ち、単一故障の後も制動できること。 */
        subject t : '自動運転トラック';
        require constraint { t.'ドライブバイワイヤ'.'ブレーキ'.'指令系統数' >= 2 }
        require constraint { t.'ドライブバイワイヤ'.'ブレーキ'.'供給系統数' >= 2 }
    }

    requirement def <'JP-R8'> RangeRequirement {
        doc /* 最大積載、80 km/h 巡航で、1 回の給油で 1000 km 以上走行できること（物流拠点間の往復を無給油で行う）。 */
        subject t : '自動運転トラック';
        require constraint { t.'航続距離km' >= 1000.0 }
    }

    requirement def <'JP-R9'> FallbackRequirement {
        doc /* 主系計算機が失陥した場合、0.1 s 以内に冗長系計算機が最小リスク操作（MRM）の指令を出すこと。 */
        subject t : '自動運転トラック';
        require constraint { t.'フォールバック遅れ' <= 0.1 [s] }
    }

    requirement def <'JP-R10'> ForwardDetectionRequirement {
        doc /* 前方認識は 250 m 以上先の停止車両と落下物を検知できること（80 km/h、積載時の停止距離に余裕を持たせる）。 */
        subject t : '自動運転トラック';
        require constraint { t.'認識センサ群'.'前方検知距離' >= 250 [m] }
    }

    requirement def <'JP-R11'> BackboneBandwidthRequirement {
        doc /* 自動運転中のセンサデータの合計は、10 Gbit/s バックボーンの 80 % 以下であること。 */
        subject t : '自動運転トラック';
        require constraint { t.'センサ総データ量Mbps' <= 0.8 * t.'キャブ'.'計算機'.'ネットワークスイッチ'.'通信容量Mbps' }
    }

    requirement def <'JP-R12'> NetAPowerRequirement {
        doc /* 24 V ネット A の自動運転関連負荷は、オルタネータ定格出力の 80 % 以下であること。 */
        subject t : '自動運転トラック';
        require constraint { t.'A系負荷' <= 0.8 * t.'電源系'.'A系供給' }
    }

    requirement def <'JP-R13'> NetBPowerRequirement {
        doc /* 24 V ネット B のフェールオペレーショナル負荷は、LFP バックアップ電池の最大出力以下であり、ネット A 失陥時に 600 s 以上給電できること。 */
        subject t : '自動運転トラック';
        require constraint { t.'B系負荷' <= t.'電源系'.'B系供給' }
        require constraint { t.'バックアップ保持時間' >= 600 [s] }
    }

    requirement def <'JP-R14'> AsilRedundancyRequirement {
        doc /* ASIL D の車両機能（操舵、制動、計算）は冗長構成とすること：独立した計算チャネル 2 以上、二重巻線モータで片側故障後も 50 % 以上のアシスト、巻線ごとのインバータ、24 V 電源 2 系統。 */
        subject t : '自動運転トラック';
        require constraint { t.'キャブ'.'計算機'.'独立系統数' >= 2 }
        require constraint { t.'ドライブバイワイヤ'.'操舵装置'.'モータ'.'巻線数' >= 2 }
        require constraint { t.'ドライブバイワイヤ'.'操舵装置'.'モータ'.'片系巻線トルク比' >= 0.5 }
        require constraint { t.'ドライブバイワイヤ'.'操舵装置'.'インバータ数' >= 2 }
        require constraint { t.'電源系'.'電源系統数' >= 2 }
    }

    requirement def <'JP-R15'> TimeSyncRequirement {
        doc /* gPTP グランドマスタは全センサと計算機の時刻を 1 マイクロ秒以内に同期させること。 */
        subject t : '自動運転トラック';
        require constraint { t.'キャブ'.'計算機'.'時刻マスタ'.'同期精度' <= 0.000001 [s] }
    }

    requirement def <'JP-R16'> RemoteMonitoringLatencyRequirement {
        doc /* 遠隔監視リンクの往復遅延（映像符号化を含む）は 0.25 s 以下であること。 */
        subject t : '自動運転トラック';
        require constraint { t.'遠隔支援'.'リンク遅れ' <= 0.25 [s] }
    }

    requirement def <'JP-R17'> ComputeCoolingRequirement {
        doc /* 計算機冷却ループの排熱能力は、主系と冗長系計算機の発熱の合計以上であること。 */
        subject t : '自動運転トラック';
        require constraint { t.'キャブ'.'計算機'.'発熱量' <= t.'熱管理'.'計算機冷却ループ'.'放熱能力' }
    }

    requirement def <'JP-R18'> CanLoadRequirement {
        doc /* シャシー CAN FD A と B のバス負荷率はそれぞれ 50 % 以下であること。 */
        subject t : '自動運転トラック';
        require constraint { t.'車載ネットワーク'.'シャシCAN_A系'.'バス負荷率' <= t.'車載ネットワーク'.'CAN負荷上限' }
        require constraint { t.'車載ネットワーク'.'シャシCAN_B系'.'バス負荷率' <= t.'車載ネットワーク'.'CAN負荷上限' }
    }

    requirement def <'JP-R19'> FailOperationalFuseRequirement {
        doc /* 操舵と制動の eFuse チャネルは、ネット A と B の両方で負荷電流以上の遮断電流を持つこと。 */
        subject t : '自動運転トラック';
        require constraint { t.'電源系'.'A系電源分配ユニット'.'ブレーキ用ヒューズ'.'遮断電流' >= t.'ドライブバイワイヤ'.'ブレーキ'.'24V電源'.current }
        require constraint { t.'電源系'.'B系電源分配ユニット'.'ブレーキ用ヒューズ'.'遮断電流' >= t.'ドライブバイワイヤ'.'ブレーキ'.'B系24V電源'.current }
        require constraint { t.'電源系'.'A系電源分配ユニット'.'操舵用ヒューズ'.'遮断電流' >= t.'ドライブバイワイヤ'.'操舵装置'.'24V電源'.current }
        require constraint { t.'電源系'.'B系電源分配ユニット'.'操舵用ヒューズ'.'遮断電流' >= t.'ドライブバイワイヤ'.'操舵装置'.'B系24V電源'.current }
    }

    requirement def <'JP-R20'> PalletCapacityRequirement {
        doc /* 荷室は T11 型パレット（1.1 m 角）を 2 列 8 段、16 枚積めること。 */
        subject t : '自動運転トラック';
        require constraint { t.'ボデー'.'荷室'.'内寸長さ' >= 8 * 1.1 [m] }
        require constraint { t.'ボデー'.'荷室'.'内寸幅' >= 2 * 1.1 [m] }
    }

    requirement def <'JP-R21'> R13ServiceBrakeRequirement {
        doc /* サービスブレーキは最大積載でタイプ 0 試験の平均飽和減速度 5.0 m/s2 以上を出せること（UN R13 附則 4、N3 車）。全ホイールのブレーキトルクとタイヤ半径から求めた制動能力と、路面摩擦係数 0.8 の粘着限界の両方で検証する。 */
        subject t : '自動運転トラック';
        require constraint { t.'制動減速能力' >= t.'R13最低減速度' }
        require constraint { t.'路面限界減速度' >= t.'R13最低減速度' }
    }

    requirement def <'JP-R22'> R13ResponseAndWarningRequirement {
        doc /* 制動指令から条件の最も悪いブレーキチャンバが漸近圧の 75 % に達するまでを 0.6 s 以内とし（UN R13 附則 6）、電気制御系統の故障を警告すること（UN R13 5.2.1.29）。 */
        subject t : '自動運転トラック';
        require constraint { t.'ドライブバイワイヤ'.'ブレーキ'.'75パーセント応答時間' <= 0.6 [s] }
        require constraint { t.'ドライブバイワイヤ'.'ブレーキ'.'EBS_ECU'.'故障警報信号' }
    }

    requirement def <'JP-R23'> R79SteeringRequirement {
        doc /* 電気的伝達を用いる操舵装置は、単一故障の後も操舵機能を保ち（片側巻線で 50 % 以上のアシスト）、故障を警告すること（UN R79 5.1.6、5.4、附則 6）。 */
        subject t : '自動運転トラック';
        require constraint { t.'ドライブバイワイヤ'.'操舵装置'.'モータ'.'巻線数' >= 2 }
        require constraint { t.'ドライブバイワイヤ'.'操舵装置'.'モータ'.'片系巻線トルク比' >= 0.5 }
        require constraint { t.'ドライブバイワイヤ'.'操舵装置'.'故障警報信号' }
    }

    requirement def <'JP-R24'> R155CybersecurityRequirement {
        doc /* UN R155 附則 5 の脅威に対する車両側の緩和策として、ゲートウェイのファイアウォール、制動、操舵指令の 64 bit 以上の SecOC 認証、遠隔監視の TLS を持つこと（UN R155 7.3.4、附則 5。CSMS 自体は組織の管理体制で、ここでは車両側を検証する）。 */
        subject t : '自動運転トラック';
        require constraint { t.'車載ネットワーク'.'ゲートウェイ'.'ファイアウォール有効' }
        require constraint { t.'車載ネットワーク'.'ゲートウェイ'.'SecOC_MACビット数' >= 64 }
        require constraint { t.'遠隔支援'.'TLS有効' }
    }

    requirement def <'JP-R25'> R156SoftwareUpdateRequirement {
        doc /* ソフトウェア更新管理システム（SUMS）の対策として、RXSWIN を読み出せ、OTA 更新は停車中に限り、失敗時は元の版に戻せること（UN R156 7.2）。 */
        subject t : '自動運転トラック';
        require constraint { t.'車載ネットワーク'.'ゲートウェイ'.'RXSWIN読出し可' }
        require constraint { t.'車載ネットワーク'.'ゲートウェイ'.'停車中のみ更新' }
        require constraint { t.'車載ネットワーク'.'ゲートウェイ'.'ロールバック対応' }
    }

    requirement def <'JP-R26'> AsilDecompositionRequirement {
        doc /* 制動、操舵指令経路の ASIL D は、独立した主系計算機と冗長系計算機の ASIL B(D) + B(D) に分解し（ISO 26262-9 第 5 節）、両者を調停する安全監視 MCU はロックステップの ASIL D とすること。分解の前提として、2 チャネルは別電源（ネット A、B）、別の CAN FD 系統で独立であること。Safety ビューに出る「D が B に依存」の指摘は、この要件が分解の根拠になる。 */
        subject t : '自動運転トラック';
        require constraint { t.'キャブ'.'計算機'.'独立系統数' >= 2 }
        require constraint { t.'キャブ'.'計算機'.'安全監視装置'.'基板'.'マイコン'.'ロックステップ' }
        require constraint { t.'電源系'.'電源系統数' >= 2 }
        require constraint { t.'ドライブバイワイヤ'.'ブレーキ'.'指令系統数' >= 2 }
    }

    requirement def <'JP-R27'> SotifTriggeringConditionRequirement {
        doc /* SOTIF の誘因条件に対して性能を保つこと（ISO 21448）：50 mm/h の強雨で前方レーダの検知距離が ODD 上限速度の停止距離以上、トンネル出口と低い太陽に対して前方カメラのダイナミックレンジが 120 dB 以上。 */
        subject t : '自動運転トラック';
        require constraint { t.'認識センサ群'.'前方レーダ'.'豪雨時検知距離' >= t.'停止距離m' * (1 [m]) }
        require constraint { t.'認識センサ群'.'狭角カメラ'.'撮像素子'.'HDR_dB' >= 120.0 }
    }

    requirement def <'JP-R28'> OddSpeedRequirement {
        doc /* 特定自動運行の運行設計領域（ODD）の上限速度は 80 km/h とし、大型貨物自動車の高速道路の法定速度（90 km/h、2024 年 4 月から）と速度抑制装置の設定（90 km/h）を超えないこと（道路交通法施行令 第 27 条、保安基準 第 8 条）。 */
        subject t : '自動運転トラック';
        require constraint { t.'ODD最高速度kmh' <= t.'法定最高速度kmh' }
        require constraint { t.'ODD最高速度kmh' <= t.'速度抑制装置kmh' }
    }

    requirement def <'JP-R29'> MrmTimeRequirement {
        doc /* ODD を外れるか主系が失陥したとき、最小リスク操作（MRM）で路肩へ車線変更して停止するまでを 30 s 以内とすること（運行設計上の目標値。特定自動運行の許可基準に数値の定めはない）。 */
        subject t : '自動運転トラック';
        require constraint { t.'MRM停止までの時間' <= t.'MRM時間上限' }
    }

    requirement def <'JP-R30'> OperationRecordRequirement {
        doc /* 運行記録計は速度、距離、時間を記録して 1 年間保存し（貨物自動車運送事業輸送安全規則 第 9 条）、作動状態記録装置は自動運行装置の作動状態を 6 か月分（または 2,500 回分）以上保存すること（保安基準 第 48 条の 3）。 */
        subject t : '自動運転トラック';
        require constraint { t.'キャブ'.'記録装置'.'タコグラフ'.'速度距離時間を記録' }
        require constraint { t.'キャブ'.'記録装置'.'タコグラフ'.'保持期間' >= 31536000 [s] }
        require constraint { t.'キャブ'.'記録装置'.'自動運行装置作動状態記録装置'.'保持期間' >= 15552000 [s] }
    }

    requirement '全長要件' : OverallLengthRequirement;
    requirement '全幅要件' : OverallWidthRequirement;
    requirement '反応時間要件' : ReactionLatencyRequirement;
    requirement '全高要件' : OverallHeightRequirement;
    requirement '車両総重量要件' : GrossVehicleMassRequirement;
    requirement '軸重要件' : AxleLoadRequirement;
    requirement 'ブレーキ冗長要件' : BrakeRedundancyRequirement;
    requirement '航続距離要件' : RangeRequirement;
    requirement 'フォールバック要件' : FallbackRequirement;
    requirement '前方検知距離要件' : ForwardDetectionRequirement;
    requirement 'バックボーン要件' : BackboneBandwidthRequirement;
    requirement 'A系電力要件' : NetAPowerRequirement;
    requirement 'B系電力要件' : NetBPowerRequirement;
    requirement 'ASIL冗長要件' : AsilRedundancyRequirement;
    requirement '時刻同期要件' : TimeSyncRequirement;
    requirement '遠隔監視要件' : RemoteMonitoringLatencyRequirement;
    requirement '計算機冷却要件' : ComputeCoolingRequirement;
    requirement 'CANバス負荷要件' : CanLoadRequirement;
    requirement 'ヒューズ要件' : FailOperationalFuseRequirement;
    requirement 'パレット積載要件' : PalletCapacityRequirement;
    requirement 'R13制動要件' : R13ServiceBrakeRequirement;
    requirement 'R13応答時間要件' : R13ResponseAndWarningRequirement;
    requirement 'R79操舵要件' : R79SteeringRequirement;
    requirement 'R155サイバーセキュリティ要件' : R155CybersecurityRequirement;
    requirement 'R156ソフトウェア更新要件' : R156SoftwareUpdateRequirement;
    requirement 'ASIL分解要件' : AsilDecompositionRequirement;
    requirement 'SOTIF要件' : SotifTriggeringConditionRequirement;
    requirement 'ODD速度要件' : OddSpeedRequirement;
    requirement 'MRM時間要件' : MrmTimeRequirement;
    requirement '作動状態記録要件' : OperationRecordRequirement;

    satisfy '全長要件' by 'キャブオーバー車';
    satisfy '全幅要件' by 'キャブオーバー車';
    satisfy '反応時間要件' by 'キャブオーバー車';
    satisfy '全高要件' by 'キャブオーバー車';
    satisfy '車両総重量要件' by 'キャブオーバー車';
    satisfy '軸重要件' by 'キャブオーバー車';
    satisfy 'ブレーキ冗長要件' by 'キャブオーバー車';
    satisfy '航続距離要件' by 'キャブオーバー車';
    satisfy 'フォールバック要件' by 'キャブオーバー車';
    satisfy '前方検知距離要件' by 'キャブオーバー車';
    satisfy 'バックボーン要件' by 'キャブオーバー車';
    satisfy 'A系電力要件' by 'キャブオーバー車';
    satisfy 'B系電力要件' by 'キャブオーバー車';
    satisfy 'ASIL冗長要件' by 'キャブオーバー車';
    satisfy '時刻同期要件' by 'キャブオーバー車';
    satisfy '遠隔監視要件' by 'キャブオーバー車';
    satisfy '計算機冷却要件' by 'キャブオーバー車';
    satisfy 'CANバス負荷要件' by 'キャブオーバー車';
    satisfy 'ヒューズ要件' by 'キャブオーバー車';
    satisfy 'パレット積載要件' by 'キャブオーバー車';
    satisfy 'R13制動要件' by 'キャブオーバー車';
    satisfy 'R13応答時間要件' by 'キャブオーバー車';
    satisfy 'R79操舵要件' by 'キャブオーバー車';
    satisfy 'R155サイバーセキュリティ要件' by 'キャブオーバー車';
    satisfy 'R156ソフトウェア更新要件' by 'キャブオーバー車';
    satisfy 'ASIL分解要件' by 'キャブオーバー車';
    satisfy 'SOTIF要件' by 'キャブオーバー車';
    satisfy 'ODD速度要件' by 'キャブオーバー車';
    satisfy 'MRM時間要件' by 'キャブオーバー車';
    satisfy '作動状態記録要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW反応時間配分要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW指令タイムアウト要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW指令E2E保護要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBWウォッチドッグ要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBWタスク周期要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW縮退時間制限要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW_MRC減速プロファイル要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW系統冗長要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW駐車ブレーキ移行要件' by 'キャブオーバー車';
    satisfy 'ブレーキECUリバースモデル'::'BBW圧力上限要件' by 'キャブオーバー車';

    /* ------------------------------------------------------------ */
    /* ユースケース：高速道路の物流拠点間輸送                           */
    /* ------------------------------------------------------------ */

    item def '物体リスト' { doc /* 融合、追跡した周辺物体（位置、速度、種別）。 */ }
    item def '走行軌道' { doc /* 今後 8 s の走行経路と速度計画。 */ }
    item def '減速指令' { doc /* XBR 減速指令（主系 0x110、冗長系 0x111、E2E 保護付き）。 */ }
    item def '圧力指令' { doc /* EBS ECU からモジュレータへの圧力指令。 */ }
    item def '運行報告' { doc /* 遠隔監視センターへ送る事象報告（位置、映像、車両状態）。 */ }

    part def '運行管理者' {
        doc /* 運行管理者。遠隔監視センターで複数台の運行を計画、監視し、停止後の再発進を承認する。 */
    }
    part def '物流拠点' {
        doc /* 物流拠点（高速道路のインターチェンジやサービスエリアに直結する中継拠点）。積み降ろしとバース誘導を行う。 */
    }
    part def '他車両' {
        doc /* 他車両。自動運転優先レーンと一般車線を走る乗用車、トラック、二輪車。 */
    }
    part def '交通管理者' {
        doc /* 交通管理者。高速道路会社の交通管制と警察。工事規制、事故、通行止めの情報を出す。 */
    }

    use case def '高速道路の拠点間輸送' {
        doc /* 高速道路の自動運転優先レーンを使い、物流拠点から物流拠点まで運転者なしで貨物を運ぶ（SAE レベル 4）。 */
        subject 'トラック' : '自動運転トラック';
        actor '運行管理' : '運行管理者';
        actor 'ハブ' : '物流拠点';
        actor '交通管制' : '他車両';
        actor '監督官庁' : '交通管理者';
        include use case '運行計画' : '運行計画を受け取る';
        include use case '出発' : '物流拠点を出発する';
        include use case '巡航' : 'L4優先レーンを走行する';
        include use case 'MRC' : 'ミニマルリスク状態に移行する';
        include use case '到着' : '物流拠点に到着する';
    }
    use case def '運行計画を受け取る' {
        doc /* 運行管理者から運行計画（経路、出発時刻、積荷）を受け取り、始業点検の結果を返す。 */
        subject 'トラック' : '自動運転トラック';
        actor '運行管理' : '運行管理者';
        actor 'ハブ' : '物流拠点';
    }
    use case def '物流拠点を出発する' {
        doc /* 拠点構内を低速で走り、ゲートを出てランプから本線へ合流する。 */
        subject 'トラック' : '自動運転トラック';
        actor 'ハブ' : '物流拠点';
        actor '交通管制' : '他車両';
    }
    use case def 'L4優先レーンを走行する' {
        doc /* 自動運転優先レーンを 80 km/h で走行し、車間維持、車線維持、工事規制への対応を行う。 */
        subject 'トラック' : '自動運転トラック';
        actor '交通管制' : '他車両';
        actor '監督官庁' : '交通管理者';
    }
    use case def 'ミニマルリスク状態に移行する' {
        doc /* 主系が継続できない故障や ODD 逸脱のとき、冗長系が路肩に停止させ、運行管理者へ通報する。 */
        subject 'トラック' : '自動運転トラック';
        actor '運行管理' : '運行管理者';
        actor '交通管制' : '他車両';
        actor '監督官庁' : '交通管理者';
    }
    use case def '物流拠点に到着する' {
        doc /* 本線を出て到着拠点のゲートを通り、指定バースに着けてウイングを開く。 */
        subject 'トラック' : '自動運転トラック';
        actor 'ハブ' : '物流拠点';
        actor '運行管理' : '運行管理者';
    }
    use case '拠点間運行' : '高速道路の拠点間輸送';

    /* ------------------------------------------------------------ */
    /* アクティビティ：認識から作動まで（MRC への切替付き）             */
    /* ------------------------------------------------------------ */

    action def '認識から制御までの周期' {
        doc /*
         * 自動運転スタックの 1 周期（10 Hz）。認識と自己位置推定を並行して行い、合流してから予測と計画へ進む。
         * 主系が継続できない故障では冗長系へ切り替え、路肩に停止する最小リスク条件（MRC）へ移る。
         */
        attribute '故障検出' : Boolean;
        attribute '到着済み' : Boolean;

        action '周辺を認識する' { out item objects : '物体リスト'; }
        action 'CLASで自己位置を推定する';
        action '物体を統合する' { in item objects : '物体リスト'; out item fused : '物体リスト'; }
        action '他車両を予測する' { in item fused : '物体リスト'; out item predicted : '物体リスト'; }
        action '軌道を計画する' { in item predicted : '物体リスト'; out item path : '走行軌道'; }
        action '減速指令を出す' { in item path : '走行軌道'; out item cmd : '減速指令'; }
        action 'フォールバックへ引き継ぐ';
        action '路肩に停止する' { out item cmd : '減速指令'; }
        action '運行管理へ報告する' { out item report : '運行報告'; }
        fork '認識';
        join '環境モデル';
        merge '完了';

        first start then '認識';
        first '認識' then '周辺を認識する';
        first '認識' then 'CLASで自己位置を推定する';
        first '周辺を認識する' then '物体を統合する';
        first '物体を統合する' then '環境モデル';
        first 'CLASで自己位置を推定する' then '環境モデル';
        first '環境モデル' then '他車両を予測する';
        first '他車両を予測する';
        then decide health;
        if '故障検出' then 'フォールバックへ引き継ぐ';
        else '軌道を計画する';
        first '軌道を計画する' then '減速指令を出す';
        first '減速指令を出す';
        then decide again;
        if '到着済み' then '完了';
        else '認識';
        first 'フォールバックへ引き継ぐ' then '路肩に停止する';
        first '路肩に停止する' then '運行管理へ報告する';
        first '運行管理へ報告する' then '完了';
        first '完了' then done;
    }
    action '認識から制御まで' : '認識から制御までの周期';

    /* ------------------------------------------------------------ */
    /* シーケンス：障害物検知から制動まで                               */
    /* ------------------------------------------------------------ */

    part def '障害物検知から制動までのシーケンス' {
        doc /* 前方 LiDAR の最初の反射から後軸ブレーキ圧の立ち上がりまでのメッセージ。JP-R3 が 0.2 s で抑える区間。 */
        @Placement { mode = LayoutMode::connectivity; }
        part 'LiDAR' : '長距離LiDAR';
        part 'レーダ' : 'イメージングレーダ';
        part 'ゾーンスイッチ' : 'ゾーンスイッチ型';
        part '主計算機' : '計算プラットフォーム';
        part '安全監視装置' : '安全監視装置型';
        part 'EBS_ECU' : 'EBS制御ユニット';
        part 'モジュレータ' : '後軸モジュレータ型';
        part '運行管理' : '運行管理者';

        message pointCloud of '物体リスト' from 'LiDAR' to 'ゾーンスイッチ';
        message radarTracks of '物体リスト' from 'レーダ' to 'ゾーンスイッチ';
        message sensorFrame of '物体リスト' from 'ゾーンスイッチ' to '主計算機';
        message detectAndPlan from '主計算機' to '主計算機';
        message heartbeat from '主計算機' to '安全監視装置';
        message xbrCommand of '減速指令' from '主計算機' to 'EBS_ECU';
        message pressureCommand of '圧力指令' from 'EBS_ECU' to 'モジュレータ';
        message pressureFeedback from 'モジュレータ' to 'EBS_ECU';
        message brakeStatus from 'EBS_ECU' to '主計算機';
        message eventReport of '運行報告' from '主計算機' to '運行管理';
    }
    verification def 'R13タイプ0試験の検証' {
        doc /* テストコースで最大積載、80 km/h から全制動し、平均飽和減速度と作動遅れを計測する（UN R13 附則 4、附則 6）。 */
        subject t : '自動運転トラック';
        objective {
            verify requirement 'R13制動要件' : R13ServiceBrakeRequirement;
            verify requirement 'R13応答時間要件' : R13ResponseAndWarningRequirement;
        }
    }
    verification def '寸法と軸重の静的検証' {
        doc /* 新規検査（車検場）の寸法測定と軸重計による各軸の計測。最大積載状態は砂袋で模擬する。 */
        subject t : '自動運転トラック';
        objective {
            verify requirement '全長要件' : OverallLengthRequirement;
            verify requirement '全幅要件' : OverallWidthRequirement;
            verify requirement '全高要件' : OverallHeightRequirement;
            verify requirement '車両総重量要件' : GrossVehicleMassRequirement;
            verify requirement '軸重要件' : AxleLoadRequirement;
        }
    }
    verification def '操舵フェイルオペレーショナルの検証' {
        doc /* HIL 台上で巻線 A を切り離し、残る巻線でのアシストトルクと警告表示を確認する（UN R79 附則 6 の故障注入）。 */
        subject t : '自動運転トラック';
        objective { verify requirement 'R79操舵要件' : R79SteeringRequirement; }
    }
    verification def 'サイバーセキュリティと更新の検証' {
        doc /* 侵入試験（CAN へのなりすまし、遠隔監視リンクへの中間者攻撃）と、走行中 OTA の拒否、失敗時のロールバックを試験する（UN R155、R156）。 */
        subject t : '自動運転トラック';
        objective {
            verify requirement 'R155サイバーセキュリティ要件' : R155CybersecurityRequirement;
            verify requirement 'R156ソフトウェア更新要件' : R156SoftwareUpdateRequirement;
        }
    }
    verification def '降雨とトンネルのSOTIF検証' {
        doc /* 降雨試験場で 50 mm/h の散水下の検知距離を計測し、トンネル出口を模した照度段差でカメラの認識を確認する（ISO 21448 の誘因条件シナリオ）。 */
        subject t : '自動運転トラック';
        objective { verify requirement 'SOTIF要件' : SotifTriggeringConditionRequirement; }
    }
    verification def '路肩へのMRMの検証' {
        doc /* 新東名の自動運転優先レーンを模したテストコースで主系を停止させ、路肩停止までの時間を計測する。 */
        subject t : '自動運転トラック';
        objective {
            verify requirement 'MRM時間要件' : MrmTimeRequirement;
            verify requirement 'フォールバック要件' : FallbackRequirement;
        }
    }
    verification def 'ブレーキ反応の検証' {
        doc /* テストコースで車線上に静止障害物を置き、80 km/h、最大積載で、最初の LiDAR 反射から後軸ブレーキ圧の立ち上がりまでを計測する。 */
        subject t : '自動運転トラック';
        objective { verify requirement '反応時間要件' : ReactionLatencyRequirement; }
    }
}
