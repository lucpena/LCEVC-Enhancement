import os
import re
import matplotlib.pyplot as plt

# Pasta contendo os arquivos .txt
pasta = 'psnr'
regex = r"n:(\d+).*?psnr_avg:([\d\.]+)"

# Lista todos os arquivos .txt
arquivos = [f for f in os.listdir(pasta) if f.endswith('.txt')]

if not arquivos:
    print("❌ Nenhum arquivo .txt encontrado na pasta 'psnr'.")
    exit()

print(f"📂 Encontrados {len(arquivos)} arquivos .txt na pasta '{pasta}'")

# Cria figura do gráfico
plt.figure(figsize=(12, 7))

for nome_arquivo in arquivos:
    caminho = os.path.join(pasta, nome_arquivo)

    frames = []
    psnr_avg = []

    print(f"🔍 Processando: {nome_arquivo}")

    with open(caminho, 'r') as file:
        for linha in file:
            match = re.search(regex, linha)
            if match:
                frames.append(int(match.group(1)))
                psnr_avg.append(float(match.group(2)))

    print(f"   ➤ {len(frames)} frames lidos com sucesso.")

    # Usa o nome do arquivo (sem extensão) como legenda
    label = os.path.splitext(nome_arquivo)[0]
    plt.plot(frames, psnr_avg, label=label)

# Configurações do gráfico
plt.title('Comparação de PSNR médio por frame')
plt.xlabel('Frame')
plt.ylabel('PSNR Médio (dB)')
plt.legend(title='Bitrates / Arquivos')
plt.grid(True)
plt.tight_layout()

# Nome do gráfico final
nome_grafico = 'grafico_comparativo_psnr.png'
plt.savefig(nome_grafico, dpi=300)

nome_grafico_high = 'grafico_comparativo_psnr_high.png'
plt.savefig(nome_grafico_high, dpi=900)

print(f"\n✅ Gráfico salvo como: {nome_grafico} e {nome_grafico_high}")
plt.show()

