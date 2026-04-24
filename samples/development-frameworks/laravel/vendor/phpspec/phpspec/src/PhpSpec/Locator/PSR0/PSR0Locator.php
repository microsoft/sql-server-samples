<?php

/*
 * This file is part of PhpSpec, A php toolset to drive emergent
 * design by specification.
 *
 * (c) Marcello Duarte <marcello.duarte@gmail.com>
 * (c) Konstantin Kudryashov <ever.zet@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace PhpSpec\Locator\PSR0;

use PhpSpec\Locator\ResourceInterface;
use PhpSpec\Locator\ResourceLocatorInterface;
use PhpSpec\Util\Filesystem;
use InvalidArgumentException;

class PSR0Locator implements ResourceLocatorInterface
{
    /**
     * @var string
     */
    private $srcPath;
    /**
     * @var string
     */
    private $specPath;
    /**
     * @var string
     */
    private $srcNamespace;
    /**
     * @var string
     */
    private $specNamespace;
    /**
     * @var string
     */
    private $fullSrcPath;
    /**
     * @var string
     */
    private $fullSpecPath;
    /**
     * @var Filesystem
     */
    private $filesystem;

    /**
     * @var string
     */
    private $psr4Prefix;

    /**
     * @param string     $srcNamespace
     * @param string     $specNamespacePrefix
     * @param string     $srcPath
     * @param string     $specPath
     * @param Filesystem $filesystem
     * @param string     $psr4Prefix
     */
    public function __construct(
        $srcNamespace = '',
        $specNamespacePrefix = 'spec',
        $srcPath = 'src',
        $specPath = '.',
        Filesystem $filesystem = null,
        $psr4Prefix = null
    ) {
        $this->filesystem = $filesystem ?: new Filesystem();
        $sepr = DIRECTORY_SEPARATOR;

        $this->srcPath       = rtrim(realpath($srcPath), '/\\').$sepr;
        $this->specPath      = rtrim(realpath($specPath), '/\\').$sepr;
        $this->srcNamespace  = ltrim(trim($srcNamespace, ' \\').'\\', '\\');
        $this->psr4Prefix    = (null === $psr4Prefix) ? null : ltrim(trim($psr4Prefix, ' \\').'\\', '\\');
        if (null !== $this->psr4Prefix  && substr($this->srcNamespace, 0, strlen($psr4Prefix)) !== $psr4Prefix) {
            throw new InvalidArgumentException('PSR4 prefix doesn\'t match given class namespace.'.PHP_EOL);
        }
        $srcNamespacePath = null === $this->psr4Prefix ?
            $this->srcNamespace :
            substr($this->srcNamespace, strlen($this->psr4Prefix));
        $this->specNamespace = $specNamespacePrefix ?
            trim($specNamespacePrefix, ' \\').'\\'.$this->srcNamespace :
            $this->srcNamespace;
        $specNamespacePath = $specNamespacePrefix ?
            trim($specNamespacePrefix, ' \\').'\\'.$srcNamespacePath :
            $srcNamespacePath;

        $this->fullSrcPath   = $this->srcPath.str_replace('\\', $sepr, $srcNamespacePath);
        $this->fullSpecPath  = $this->specPath.str_replace('\\', $sepr, $specNamespacePath);

        if ($sepr === $this->srcPath) {
            throw new InvalidArgumentException(sprintf(
                'Source code path should be existing filesystem path, but "%s" given.',
                $srcPath
            ));
        }

        if ($sepr === $this->specPath) {
            throw new InvalidArgumentException(sprintf(
                'Specs code path should be existing filesystem path, but "%s" given.',
                $specPath
            ));
        }
    }

    /**
     * @return string
     */
    public function getFullSrcPath()
    {
        return $this->fullSrcPath;
    }

    /**
     * @return string
     */
    public function getFullSpecPath()
    {
        return $this->fullSpecPath;
    }

    /**
     * @return string
     */
    public function getSrcNamespace()
    {
        return $this->srcNamespace;
    }

    /**
     * @return string
     */
    public function getSpecNamespace()
    {
        return $this->specNamespace;
    }

    /**
     * @return ResourceInterface[]
     */
    public function getAllResources()
    {
        return $this->findSpecResources($this->fullSpecPath);
    }

    /**
     * @param string $query
     *
     * @return bool
     */
    public function supportsQuery($query)
    {
        $path = $this->getQueryPath($query);

        if (null === $path) {
            return false;
        }

        return 0 === strpos($path, $this->srcPath)
            || 0 === strpos($path, $this->specPath)
        ;
    }

    /**
     * @return boolean
     */
    public function isPSR4()
    {
        return $this->psr4Prefix !== null;
    }

    /**
     * @param string $query
     *
     * @return ResourceInterface[]
     */
    public function findResources($query)
    {
        $path = $this->getQueryPath($query);

        if ('.php' !== substr($path, -4)) {
            $path .= DIRECTORY_SEPARATOR;
        }

        if ($path && 0 === strpos($path, $this->fullSpecPath)) {
            return $this->findSpecResources($path);
        }

        if ($path && 0 === strpos($path, $this->fullSrcPath)) {
            $path = $this->fullSpecPath.substr($path, strlen($this->fullSrcPath));
            $path = preg_replace('/\.php/', 'Spec.php', $path);

            return $this->findSpecResources($path);
        }

        if ($path && 0 === strpos($path, $this->srcPath)) {
            $path = $this->fullSpecPath.substr($path, strlen($this->srcPath));
            $path = preg_replace('/\.php/', 'Spec.php', $path);

            return $this->findSpecResources($path);
        }

        return array();
    }

    /**
     * @param string $classname
     *
     * @return bool
     */
    public function supportsClass($classname)
    {
        $classname = str_replace('/', '\\', $classname);

        return '' === $this->srcNamespace
            || 0  === strpos($classname, $this->srcNamespace)
            || 0  === strpos($classname, $this->specNamespace)
        ;
    }

    /**
     * @param string $classname
     *
     * @return null|PSR0Resource
     */
    public function createResource($classname)
    {
        $this->validatePsr0Classname($classname);

        $classname = str_replace('/', '\\', $classname);

        if (0 === strpos($classname, $this->specNamespace)) {
            $relative = substr($classname, strlen($this->specNamespace));

            return new PSR0Resource(explode('\\', $relative), $this);
        }

        if ('' === $this->srcNamespace || 0 === strpos($classname, $this->srcNamespace)) {
            $relative = substr($classname, strlen($this->srcNamespace));

            return new PSR0Resource(explode('\\', $relative), $this);
        }

        return null;
    }

    /**
     * @return int
     */
    public function getPriority()
    {
        return 0;
    }

    /**
     * @param string $path
     *
     * @return PSR0Resource[]
     */
    protected function findSpecResources($path)
    {
        if (!$this->filesystem->pathExists($path)) {
            return array();
        }

        if ('.php' === substr($path, -4)) {
            return array($this->createResourceFromSpecFile(realpath($path)));
        }

        $resources = array();
        foreach ($this->filesystem->findSpecFilesIn($path) as $file) {
            $resources[] = $this->createResourceFromSpecFile($file->getRealPath());
        }

        return $resources;
    }

    /**
     * @param $path
     *
     * @return null|string
     */
    private function findSpecClassname($path)
    {
        // Find namespace and class name
        $namespace = '';
        $content   = $this->filesystem->getFileContents($path);
        $tokens    = token_get_all($content);
        $count     = count($tokens);

        for ($i = 0; $i < $count; $i++) {
            if ($tokens[$i][0] === T_NAMESPACE) {
                for ($j = $i + 1; $j < $count; $j++) {
                    if ($tokens[$j][0] === T_STRING) {
                        $namespace .= $tokens[$j][1].'\\';
                    } elseif ($tokens[$j] === '{' || $tokens[$j] === ';') {
                        break;
                    }
                }
            }

            if ($tokens[$i][0] === T_CLASS) {
                for ($j = $i+1; $j < $count; $j++) {
                    if ($tokens[$j] === '{') {
                        return $namespace.$tokens[$i+2][1];
                    }
                }
            }
        }

        // No class found
        return null;
    }

    /**
     * @param string $path
     *
     * @return PSR0Resource
     */
    private function createResourceFromSpecFile($path)
    {
        $classname = $this->findSpecClassname($path);

        if (null === $classname) {
            throw new \RuntimeException('Spec file does not contains any class definition.');
        }

        // Remove spec namespace from the begining of the classname.
        $specNamespace = trim($this->getSpecNamespace(), '\\').'\\';

        if (0 !== strpos($classname, $specNamespace)) {
            throw new \RuntimeException(sprintf(
                'Spec class `%s` must be in the base spec namespace `%s`.',
                $classname,
                $this->getSpecNamespace()
            ));
        }

        $classname = substr($classname, strlen($specNamespace));

        // cut "Spec" from the end
        $classname = preg_replace('/Spec$/', '', $classname);

        // Create the resource
        return new PSR0Resource(explode('\\', $classname), $this);
    }

    /**
     * @param string $classname
     *
     * @throws InvalidArgumentException
     */
    private function validatePsr0Classname($classname)
    {
        $pattern = '/^([a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*[\/\\\\]?)*[a-zA-Z_\x7f-\xff][a-zA-Z0-9_\x7f-\xff]*$/';

        if (!preg_match($pattern, $classname)) {
            throw new InvalidArgumentException(
                sprintf('String "%s" is not a valid class name.', $classname).PHP_EOL.
                'Please see reference document: '.
                'https://github.com/php-fig/fig-standards/blob/master/accepted/PSR-0.md'
            );
        }
    }

    /**
     * @param string $query
     *
     * @return string
     */
    private function getQueryPath($query)
    {
        $sepr = DIRECTORY_SEPARATOR;
        $replacedQuery = str_replace(array('\\', '/'), $sepr, $query);

        if ($this->queryContainsQualifiedClassName($query)) {
            $namespacedQuery = null === $this->psr4Prefix ?
                $replacedQuery :
                substr($replacedQuery, strlen($this->srcNamespace));

            $path = $this->fullSpecPath . $namespacedQuery . 'Spec.php';

            if ($this->filesystem->pathExists($path)) {
                return $path;
            }
        }

        return rtrim(realpath($replacedQuery), $sepr);
    }

    /**
     * @param string $query
     *
     * @return bool
     */
    private function queryContainsQualifiedClassName($query)
    {
        return $this->queryContainsBlackslashes($query) && !$this->isWindowsPath($query);
    }

    /**
     * @param string $query
     *
     * @return bool
     */
    private function queryContainsBlackslashes($query)
    {
        return false !== strpos($query, '\\');
    }

    /**
     * @param string $query
     *
     * @return bool
     */
    private function isWindowsPath($query)
    {
        return preg_match('/^\w:/', $query);
    }
}
