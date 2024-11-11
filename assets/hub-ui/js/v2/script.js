document.addEventListener('DOMContentLoaded', () => {
    initialize();

    // Global error handling
    window.addEventListener('error', handleGlobalError);

    // Display a notice using SweetAlert
    swal({
        title: "温馨提示",
        content: createSwalContent(),
        icon: "info"
    });
});

function initialize() {
    // Start the time updater interval
    const timeUpdateInterval = setInterval(updateTime, 1000);
    updateTime();

    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.addEventListener('keypress', debounce((event) => {
            if (event.key === 'Enter') {
                performSearch();
            }
        }, 300));
    }

    // Update Cloudflare information
    updateCloudflareInfo();

    return () => {
        clearInterval(timeUpdateInterval);
    };
}

function handleGlobalError(event) {
    console.error('未处理的错误:', event.error);
    swal("系统提示", "发生了一个未处理的错误，请稍后重试。", "error");
}

function updateTime() {
    const now = new Date();
    const dateElement = document.getElementById('current-date');
    const timeElement = document.getElementById('current-time');

    if (dateElement && timeElement) {
        dateElement.textContent = formatDate(now);
        timeElement.textContent = now.toLocaleTimeString('zh-CN', { hour12: false });
    }
}

function performSearch() {
    const searchInput = document.getElementById('search-input');
    const query = searchInput.value.trim();

    if (query) {
        try {
            const encodedQuery = encodeURIComponent(query);
            window.location.href = `/search?q=${encodedQuery}`;
        } catch (error) {
            swal("搜索错误", "无法处理搜索请求，请检查。", "error");
        }
    } else {
        swal("请输入搜索内容", "搜索框不能为空。", "warning");
    }
}

function copyCode(button) {
    const codeElement = button.previousElementSibling;
    if (!codeElement) return;

    const code = codeElement.textContent.trim();

    navigator.clipboard.writeText(code)
        .then(() => swal("复制成功", "代码已复制到剪贴板！", "success"))
        .catch(err => {
            console.error('复制失败', err);
            fallbackCopyTextToClipboard(code);
        });
}

function fallbackCopyTextToClipboard(text) {
    const tempTextArea = document.createElement("textarea");
    tempTextArea.value = text;
    tempTextArea.style.position = "fixed";
    tempTextArea.style.opacity = "0";
    document.body.appendChild(tempTextArea);

    try {
        tempTextArea.select();
        document.execCommand('copy');
        swal("复制成功", "代码已复制到剪贴板！", "success");
    } catch (err) {
        console.error('复制失败', err);
        swal("复制失败", "无法复制代码。", "error");
    } finally {
        document.body.removeChild(tempTextArea);
    }
}

async function updateCloudflareInfo() {
    const cfItems = document.querySelectorAll("#cf .cf-item");
    if (!cfItems || cfItems.length < 7) return;

    try {
        const response = await fetch('/cdn-cgi/trace', {
            cache: 'no-store',
            headers: {
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache'
            }
        });

        if (!response.ok) throw new Error(`HTTP错误: ${response.status}`);

        const data = await response.text();
        const info = parseTraceData(data);

        const fields = ['loc', 'ip', 'colo', 'http', 'scheme', 'tls', 'kex'];

        fields.forEach((field, index) => {
            cfItems[index].textContent = `${field}:${info[field] || 'N/A'}`;
        });

    } catch (error) {
        console.error('获取Cloudflare信息失败', error);
        cfItems.forEach(item => item.textContent = '无法获取信息');
    }
}

function parseTraceData(data) {
    return data.split('\n').reduce((info, line) => {
        const [key, value] = line.split('=');
        if (key && value) info[key] = value.trim();
        return info;
    }, {});
}

function createSwalContent() {
    const wrapper = document.createElement('div');
    wrapper.innerHTML = `
        由于 Cloudflare Worker 每日请求数量限制，本网站已经限制了部分站点请求（不包括真实 IP，也不支持 docker 容器的真实 IP）。
        对于此类请求，HTTP 状态码将返回 403，部分用户访问网站返回 403 仅作为正常业务状态。<br><br>
        具体监控方式：Uptime Kuma`;
    return wrapper;
}

// Utility functions
function debounce(func, wait = 300) {
    let timeout;
    return function (...args) {
        const context = this;
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(context, args), wait);
    };
}

function formatDate(date, options = {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit'
}) {
    return new Intl.DateTimeFormat('zh-CN', options).format(date);
}