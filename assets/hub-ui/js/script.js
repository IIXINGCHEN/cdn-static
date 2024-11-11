(function () {
    function hashCode(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            const char = str.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        return Math.abs(hash).toString(16);
    }

    function loadStylesheet() {
        const stylesheetHref = 'https://static.axingchen.com/assets/hub-ui/css/style.css?v=hash_value';

        let link = document.querySelector('link[href^="https://static.axingchen.com/assets/hub-ui/css/style.css"]');

        if (!link) {
            link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = stylesheetHref;
            document.head.appendChild(link);
        }

        link.onload = function () {
            console.log("CSS已加载完成");
            document.documentElement.style.visibility = 'visible';  // 显示页面
        };

        link.onerror = function () {
            console.error('CSS加载失败');
            alert('CSS加载失败，请检查网络或稍后重试。');  // 用户提示
        };

        document.documentElement.style.visibility = 'hidden';  // 隐藏页面直到CSS加载完成
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', loadStylesheet);
    } else {
        loadStylesheet();
    }
})();

document.addEventListener('DOMContentLoaded', function () {
    setInterval(updateTime, 1000);
    updateTime();

    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.addEventListener('keypress', function (event) {
            if (event.key === 'Enter') {
                performSearch();
            }
        });
    }

    window.addEventListener('error', function (event) {
        console.error('捕获到未处理的错误:', event.error);
        swal("系统提示", "发生了一个意外错误，请稍后重试。", "error");
    });

    updateCloudflareInfo();

    //  SweetAlert
    swal({
        title: "温馨提示",
        content: createSwalContent(),
        icon: "info"
    });
});

function updateTime() {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const seconds = now.getSeconds().toString().padStart(2, '0');

    const dateElement = document.getElementById('current-date');
    const timeElement = document.getElementById('current-time');

    if (dateElement && timeElement) {
        dateElement.innerHTML = `${year}-${month}-${day}`;
        timeElement.innerHTML = `${hours}:${minutes}:${seconds}`;
    }
}

function performSearch() {
    const query = document.getElementById('search-input').value.trim();
    if (query) {
        window.location.href = '/search?q=' + encodeURIComponent(query);
    } else {
        swal("请输入搜索内容", "搜索框不能为空。", "warning");
    }
}

function copyCode(button) {
    const codeElement = button.previousElementSibling;
    if (codeElement) {
        const code = codeElement.textContent;
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(code).then(() => {
                swal("复制成功", "代码已复制到剪贴板！", "success");
            }).catch(err => {
                console.error('复制失败: ', err);
                fallbackCopyTextToClipboard(code);
            });
        } else {
            fallbackCopyTextToClipboard(code);
        }
    }
}

function fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-999999px";
    textArea.style.top = "-999999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        const successful = document.execCommand('copy');
        if (successful) {
            swal("复制成功", "代码已复制到剪贴板！", "success");
        } else {
            throw new Error('复制命令未成功执行');
        }
    } catch (err) {
        console.error('复制失败: ', err);
        swal("复制失败", "无法复制代码。", "error");
    }

    document.body.removeChild(textArea);
}

async function updateCloudflareInfo() {
    const endpoint = '/cdn-cgi/trace';
    const fields = ['loc', 'ip', 'colo', 'http', 'visit_scheme', 'tls', 'kex'];

    try {
        const response = await fetch(endpoint, {
            cache: 'no-store',
            headers: {
                'Cache-Control': 'no-cache',
                'Pragma': 'no-cache'
            }
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.text();
        const info = parseTraceData(data);

        if (isValidInfo(info, fields)) {
            const locIpLine = `loc: ${info['loc']} | ip:${info['ip']}`;
            const combinedMainLine = `colo: ${info['colo']} | http:${info['http']} | visit_scheme: ${info['visit_scheme']}`;
            const tlsKexLine = `tls: ${info['tls']} | kex:${info['kex']}`;

            const displayText = [locIpLine, combinedMainLine, tlsKexLine].join('\n');

            const cfElement = document.getElementById('cf');
            if (cfElement) {
                cfElement.textContent = displayText;
            } else {
                console.error('Element with id "cf" not found.');
            }
        } else {
            console.error('Invalid trace data received.');
            const cfElement = document.getElementById('cf');
            if (cfElement) {
                cfElement.textContent = '获取的Cloudflare信息无效';
            }
        }
    } catch (error) {
        console.error('获取Cloudflare节点信息失败: ', error);
        const cfElement = document.getElementById('cf');
        if (cfElement) {
            cfElement.textContent = '无法获取Cloudflare节点信息';
        }
    }
}

function parseTraceData(data) {
    const info = {};
    data.split('\n').forEach(line => {
        const parts = line.split('=');
        if (parts.length === 2) {
            info[parts[0]] = parts[1];
        }
    });
    return info;
}

function isValidInfo(info, fields) {
    return fields.every(field => info.hasOwnProperty(field));
}

function createSwalContent() {
    const div = document.createElement("div");
    div.innerHTML = "由于cloudflare worker每日请求次数有限，目前本网站已经屏蔽部分监控本站请求（不会拉黑IP，也不影响docker镜像的拉取），" +
        "对于此类请求，HTTP状态码将返回403，部分监控工具检测到网站返回403可视为网站处于正常运营状态。<br><br>" +
        "已屏蔽监控工具：Uptime Kuma";
    return div;
}

// 需要定义 debounce, throttle 和 formatDate 函数
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let lastFunc;
    let lastRan;
    return function() {
        const context = this;
        const args = arguments;
        if (!lastRan) {
            func.apply(context, args);
            lastRan = Date.now();
        } else {
            clearTimeout(lastFunc);
            lastFunc = setTimeout(function() {
                if ((Date.now() - lastRan) >= limit) {
                    func.apply(context, args);
                    lastRan = Date.now();
                }
            }, limit - (Date.now() - lastRan));
        }
    };
}

function formatDate(date) {
    const options = { year: 'numeric', month: '2-digit', day: '2-digit' };
    return new Intl.DateTimeFormat('zh-CN', options).format(date);
}

window.utils = {
    debounce,
    throttle,
    formatDate
};
